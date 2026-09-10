import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { readdir, stat } from "node:fs/promises";
import { join } from "node:path";

function buildImplementationPrompt(specPath: string): string {
  return `Implement @${specPath} end-to-end.

Operate autonomously using ~/.pi/agent/skills/mholtzscher/agent-orchestrator/SKILL.md 
1. Read the specification completely and follow all repository instructions.
2. Use available subagents for bounded discovery, implementation, or validation work so the main context stays focused. Prefer foreground agents over background agents.
3. Keep a concise log of assumptions and include it in the PR description and final report. Do not create a separate assumptions file unless the specification requests one.
4. Implement the smallest complete solution and run all relevant local validation.
5. Create or use an appropriate branch, commit and push the changes, and publish a pull request.
6. Monitor all required GitHub Actions checks until they finish successfully. If a check fails, investigate it, fix the issue, validate locally, push the update, and repeat until the required checks pass.

Only stop to ask for help when blocked by missing credentials or permissions, or when an ambiguity could cause a destructive or materially different outcome.`;
}

function buildStackedImplementationPrompt(specPath: string): string {
  return `Implement @${specPath} end-to-end as a stack of pull requests, one per deliverable, using the official gh stack extension (github/gh-stack, stacked PRs public preview).

Operate autonomously using ~/.pi/agent/skills/mholtzscher/agent-orchestrator/SKILL.md
1. Read the specification completely and follow all repository instructions. Identify the ordered deliverables (e.g. Deliverables Ordered, Ordered implementation steps, Scope & Deliverables). If the spec has no explicit deliverables, infer the smallest sensible ordered split and proceed.
2. Use available subagents for bounded discovery, implementation, or validation work so the main context stays focused. Prefer foreground agents over background agents.
3. Keep a concise log of assumptions and include it in each PR description and the final report. Do not create a separate assumptions file unless the specification requests one.
4. Manage the stack with gh stack (assume the github/gh-stack extension is installed):
   a. Discover the trunk via \`gh repo view --json defaultBranchRef\`; never assume main/master.
   b. Start from a clean trunk checkout, then \`gh stack init <first-branch-kebab-case>\` for the first deliverable.
   c. For each deliverable in dependency order: implement the smallest complete solution for that deliverable only, run all relevant local validation, commit with a conventional commit message, then open the next layer with \`gh stack add <next-branch-kebab-case>\` (or \`gh stack add -Am "<message>"\` to stage/commit in one step). Title each layer the same as its commit subject; each PR body must state the deliverable number, what changed and why, verification steps, and the stack order.
   d. Publish with \`gh stack push && gh stack submit\` so each branch gets a PR based on the branch below it (first targets trunk). Use \`gh stack view\` to confirm links and order.
   e. Monitor all required GitHub Actions checks per PR until green. If a check fails, fix on the corresponding layer (\`gh stack checkout <branch>\`), validate locally, \`gh stack push\`, and repeat; use \`gh stack rebase\` to cascade trunk/stack updates when needed. Do not move to the next deliverable until the current layer's checks pass.
5. Report the full stack in dependency order (bottom to top) with a PR URL per deliverable plus a one-line summary of each branch, commit, and PR.

Only stop to ask for help when blocked by missing credentials or permissions, or when an ambiguity could cause a destructive or materially different outcome.`;
}

function buildScrubTaskPrompt(specPath: string): string {
  return `Review and refine @${specPath} for cohesiveness and brevity.

Goals:

- Preserve all approved product behavior, implementation contracts, invariants, API semantics, and acceptance criteria.
- Remove repetition across recommendations, invariants, non-goals, contracts, acceptance criteria, test strategy, risks, trade-offs, rollout, and success criteria.
- Remove stale details from prior revisions—especially unrelated negative cases that only reject designs the current spec no longer suggests.
- Prefer positive statements of the chosen behavior over exhaustive lists of what will not be built.
- Retain negative cases only when they directly protect scope, privacy, security, compatibility, or error semantics.
- Consolidate identical or overlapping types, interfaces, requirements, and verification steps where doing so does not change behavior.
- Standardize terminology and identify contradictions or mismatched ownership.
- Keep concrete schema, type, interface, route, error, concurrency, configuration, and testing contracts needed for implementation.

Process:

1. Read the spec and its Git history to identify residue from earlier designs.
2. State any assumptions or semantic conflicts before changing them.
3. Edit the file directly, making the smallest changes needed for substantial compression.
4. Do not introduce new product or architectural decisions merely to simplify the prose.
5. Verify formatting and run the repository’s required validation command.

When finished, report:

- Original and final line/word counts.
- The main categories of duplication or stale material removed.
- Any unresolved contradictions or decisions needing owner input.
- Validation results.`;
}

function buildScrubPrompt(specPath: string): string {
  return `/skill:unslop ${buildScrubTaskPrompt(specPath)}`;
}

function buildAnnotationPrompt(specPath: string): string {
  return `/plannotator-annotate @${specPath}`;
}

function buildBackgroundScrubPrompt(specPath: string): string {
  const prompt = `Before editing, read and follow the unslop skill at ~/.pi/agent/skills/pstack/unslop/SKILL.md.\n\n${buildScrubTaskPrompt(specPath)}`;

  return `Call the Agent tool exactly once with these arguments:

- agent: "general-purpose"
- description: "Scrub ${specPath}"
- run_in_background: true
- prompt: ${JSON.stringify(prompt)}

Do not scrub the specification yourself. After the Agent tool confirms the background spawn, stop.`;
}

type SpecRecency = {
  name: string;
  /** 0 for uncommitted files, 1 for committed ones; lower sorts first. */
  rank: number;
  /** Milliseconds: mtime when uncommitted, committer date when committed. */
  recency: number;
};

/** Runs git, resolving to null instead of rejecting so callers can treat failure as "no git". */
function runGit(args: string[], cwd: string): Promise<string | null> {
  return new Promise((resolve) => {
    execFile(
      "git",
      args,
      { cwd, encoding: "utf8", timeout: 5_000, maxBuffer: 4 * 1024 * 1024 },
      (error, stdout) => resolve(error ? null : stdout),
    );
  });
}

/**
 * Names of spec files with uncommitted changes, relative to specsDirectory, or null when
 * specsDirectory is not in a git repository. Covers staged, unstaged, and untracked files.
 */
async function readUncommittedSpecNames(specsDirectory: string): Promise<Set<string> | null> {
  const prefix = await runGit(["rev-parse", "--show-prefix"], specsDirectory);
  if (prefix === null) return null;

  // --no-renames avoids the extra source path that -z emits for rename entries.
  const status = await runGit(
    ["status", "--porcelain", "-z", "--no-renames", "--", "."],
    specsDirectory,
  );
  if (status === null) return null;

  // git status paths are always repository-root relative, so strip the specs/ prefix.
  const pathPrefix = prefix.trim();
  return new Set(
    status
      .split("\0")
      .filter((entry) => entry.length > 0)
      .map((entry) => entry.slice(3))
      .filter((path) => path.startsWith(pathPrefix))
      .map((path) => path.slice(pathPrefix.length)),
  );
}

/** Committer date in milliseconds of the last commit touching the file, or null when untracked. */
async function readLastCommitTimeMs(specsDirectory: string, name: string): Promise<number | null> {
  const stdout = await runGit(["log", "-1", "--format=%ct", "--", name], specsDirectory);
  if (stdout === null) return null;

  const seconds = Number.parseInt(stdout.trim(), 10);
  return Number.isFinite(seconds) ? seconds * 1000 : null;
}

/**
 * Orders spec file names newest first. Worktree checkouts stamp every file with the same mtime,
 * so uncommitted files use their mtime (which the editor just refreshed) and committed files use
 * the last commit that touched them. Without git, every file falls back to mtime.
 */
async function orderSpecsByRecency(specsDirectory: string, names: string[]): Promise<string[]> {
  const uncommitted = await readUncommittedSpecNames(specsDirectory);

  const recencies: SpecRecency[] = await Promise.all(
    names.map(async (name) => {
      // Uncommitted files keep their mtime: the editor just wrote them, so it is meaningful.
      const committedAt =
        uncommitted === null || uncommitted.has(name)
          ? null
          : await readLastCommitTimeMs(specsDirectory, name);

      return {
        name,
        rank: committedAt === null ? 0 : 1,
        recency: committedAt ?? (await stat(join(specsDirectory, name))).mtimeMs,
      };
    }),
  );

  return recencies
    .sort(
      (left, right) =>
        left.rank - right.rank ||
        right.recency - left.recency ||
        left.name.localeCompare(right.name),
    )
    .map((entry) => entry.name);
}

type SpecCommand = {
  name: string;
  description: string;
  pickerTitle: string;
  buildPrompt: (specPath: string) => string;
};

function registerSpecCommand(pi: ExtensionAPI, command: SpecCommand): void {
  pi.registerCommand(command.name, {
    description: command.description,
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify(`/${command.name} requires an interactive UI`, "warning");
        return;
      }

      await ctx.waitForIdle();

      const specsDirectory = join(ctx.cwd, "specs");
      let specs: string[];

      try {
        const files = (await readdir(specsDirectory, { withFileTypes: true })).filter((entry) =>
          entry.isFile(),
        );

        specs = await orderSpecsByRecency(
          specsDirectory,
          files.map((entry) => entry.name),
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Could not read specs/: ${message}`, "error");
        return;
      }

      if (specs.length === 0) {
        ctx.ui.notify("No files found in specs/", "warning");
        return;
      }

      const selected = await ctx.ui.select(command.pickerTitle, specs);
      if (!selected) return;

      pi.sendUserMessage(command.buildPrompt(`specs/${selected}`), { expandPromptTemplates: true });
    },
  });
}

export default function (pi: ExtensionAPI) {
  registerSpecCommand(pi, {
    name: "implement-spec",
    description: "Choose a file from specs/ and ask the agent to implement it",
    pickerTitle: "Choose a specification to implement",
    buildPrompt: buildImplementationPrompt,
  });
  registerSpecCommand(pi, {
    name: "implement-spec-stacked",
    description: "Choose a file from specs/ and ask the agent to implement it as stacked PRs, one per deliverable",
    pickerTitle: "Choose a specification to implement as a stack",
    buildPrompt: buildStackedImplementationPrompt,
  });
  registerSpecCommand(pi, {
    name: "scrub-spec",
    description: "Choose a file from specs/ and ask the agent to refine it",
    pickerTitle: "Choose a specification to refine",
    buildPrompt: buildScrubPrompt,
  });
  registerSpecCommand(pi, {
    name: "spec-annotate",
    description: "Choose a file from specs/ and annotate it with Plannotator",
    pickerTitle: "Choose a specification to annotate",
    buildPrompt: buildAnnotationPrompt,
  });
  registerSpecCommand(pi, {
    name: "scrub-spec-bg",
    description: "Choose a file from specs/ and refine it in a background subagent",
    pickerTitle: "Choose a specification to refine in the background",
    buildPrompt: buildBackgroundScrubPrompt,
  });
}
