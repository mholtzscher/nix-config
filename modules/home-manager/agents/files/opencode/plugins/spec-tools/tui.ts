import { execFile } from "node:child_process";
import { readdir, stat } from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";

import { Plugin } from "@opencode/plugin/tui";

interface CommandContext {
  cwd: string;
  hasUI: true;
  signal: AbortSignal;
  waitForIdle: () => Promise<void>;
  ui: {
    input: (title: string) => Promise<string | undefined>;
    notify: (message: string, level: "error" | "info" | "warning") => void;
    select: (title: string, options: string[]) => Promise<string | undefined>;
  };
}

interface OpenCodeCommandHost {
  registerCommand: (
    name: string,
    command: {
      description: string;
      handler: (args: string, context: CommandContext) => Promise<void>;
    }
  ) => void;
  sendUserMessage: (
    prompt: string,
    options?: { expandPromptTemplates?: boolean }
  ) => void;
}

// @types/node declares promisify() as taking a void-returning callback function,
// so execFile (whose callback also yields stdout/stderr) trips strict-void-return.
// oxlint-disable-next-line typescript/strict-void-return
const execFileAsync = promisify(execFile);

const GIT_TIMEOUT_MS = 5000;
const GIT_MAX_BUFFER = 4 * 1024 * 1024;

const buildImplementationPrompt = (specPath: string): string =>
  `Implement @${specPath} end-to-end.

Operate autonomously using the agent-orchestrator skill.
1. Read the specification completely and follow all repository instructions.
2. Use available subagents for bounded discovery, implementation, or validation work so the main context stays focused. Prefer foreground agents over background agents.
3. Keep a concise log of assumptions and include it in the PR description and final report. Do not create a separate assumptions file unless the specification requests one.
4. Implement the smallest complete solution and run all relevant local validation.
5. Create or use an appropriate branch, commit and push the changes, and publish a pull request.
6. Monitor all required GitHub Actions checks until they finish successfully. If a check fails, investigate it, fix the issue, validate locally, push the update, and repeat until the required checks pass.

Only stop to ask for help when blocked by missing credentials or permissions, or when an ambiguity could cause a destructive or materially different outcome.`;

const buildStackedImplementationPrompt = (specPath: string): string =>
  `Implement @${specPath} end-to-end as a stack of pull requests, one per deliverable, using the official gh stack extension (github/gh-stack, stacked PRs public preview).

Operate autonomously using the agent-orchestrator skill.
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

const buildScrubTaskPrompt = (specPath: string): string =>
  `Review and refine @${specPath} for cohesiveness and brevity.

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

const buildScrubPrompt = (specPath: string): string =>
  `Use the unslop skill for this task.\n\n${buildScrubTaskPrompt(specPath)}`;

export const buildSimplifyPrompt = (specPath: string): string =>
  `Read @${specPath} completely.

Now come up with a much simpler solution that provides 80% of the benefits we are talking about here.

Goals:

- Identify the core user value — the 20% of the spec delivering 80% of the benefit — and center the simpler solution on that.
- Ruthlessly cut scope: defer nice-to-haves, edge cases, premature abstractions, and speculative extensibility.
- Prefer boring, proven approaches: fewer moving parts, fewer new types, interfaces, routes, and config options, less concurrency and error-handling surface.
- Preserve the spec's intent for the core use case; explicitly list what is dropped or deferred and why the trade-off is worth it.

Process:

1. State in one or two sentences what the highest-value outcome of the spec is.
2. Propose the simpler solution: what to build instead, end to end.
3. Compare the two: what is kept, what is cut or deferred, and roughly how much complexity each cut saves.
4. Call out what is lost — the 20% of benefits given up — so it is an explicit decision.

Do not edit any files. Present the simpler alternative in chat and wait for direction before changing the spec.`;

const buildAnnotationPrompt = (specPath: string): string =>
  `/plannotator-annotate @${specPath}`;

export const buildBackgroundScrubPrompt = (specPath: string): string => {
  const prompt = `Before editing, load and follow the unslop skill.\n\n${buildScrubTaskPrompt(specPath)}`;

  return `Call the subagent tool exactly once with these arguments:

- agent: "general"
- description: "Scrub ${specPath}"
- background: true
- prompt: ${JSON.stringify(prompt)}

Do not scrub the specification yourself. After the subagent tool confirms the background spawn, stop.`;
};

const buildCreateSpecPrompt = (idea: string): string =>
  `Invoke the grill-with-docs skill.

Idea:

${idea}

When the interview and domain model are complete, invoke the spec-planner skill and produce the implementation-ready spec through dialogue.`;

interface SpecRecency {
  name: string;
  /** Milliseconds: mtime when uncommitted, committer date when committed. */
  recency: number;
}

/** Runs git, resolving to null instead of rejecting so callers can treat failure as "no git". */
const runGit = async (
  args: string[],
  cwd: string,
  signal: AbortSignal
): Promise<string | null> => {
  try {
    const { stdout } = await execFileAsync("git", args, {
      cwd,
      encoding: "utf-8",
      maxBuffer: GIT_MAX_BUFFER,
      signal,
      timeout: GIT_TIMEOUT_MS,
    });
    return stdout;
  } catch {
    return null;
  }
};

/**
 * Names of spec files with uncommitted changes, relative to specsDirectory, or null when
 * specsDirectory is not in a git repository. Covers staged, unstaged, and untracked files.
 */
const readUncommittedSpecNames = async (
  specsDirectory: string,
  signal: AbortSignal
): Promise<Set<string> | null> => {
  const prefix = await runGit(
    ["rev-parse", "--show-prefix"],
    specsDirectory,
    signal
  );
  if (prefix === null) {
    return null;
  }

  // --no-renames avoids the extra source path that -z emits for rename entries.
  const status = await runGit(
    ["status", "--porcelain", "-z", "--no-renames", "--", "."],
    specsDirectory,
    signal
  );
  if (status === null) {
    return null;
  }

  // git status paths are always repository-root relative, so strip the specs/ prefix.
  const pathPrefix = prefix.trim();
  return new Set(
    status
      .split("\0")
      .filter((entry) => entry.length > 0)
      .map((entry) => entry.slice(3))
      .filter((entry) => entry.startsWith(pathPrefix))
      .map((entry) => entry.slice(pathPrefix.length))
  );
};

/** Committer date in milliseconds of the last commit touching the file, or null when untracked. */
const readLastCommitTimeMs = async (
  specsDirectory: string,
  name: string,
  signal: AbortSignal
): Promise<number | null> => {
  const stdout = await runGit(
    ["log", "-1", "--format=%ct", "--", name],
    specsDirectory,
    signal
  );
  if (stdout === null) {
    return null;
  }

  const raw = stdout.trim();
  if (raw === "") {
    return null;
  }
  const seconds = Math.trunc(Number(raw));
  return Number.isFinite(seconds) ? seconds * 1000 : null;
};

/**
 * Orders spec file names newest first. Worktree checkouts stamp every file with the same mtime,
 * so uncommitted files use their mtime (which the editor just refreshed) and committed files use
 * the last commit that touched them. Without git, every file falls back to mtime.
 */
const orderSpecsByRecency = async (
  specsDirectory: string,
  names: string[],
  signal: AbortSignal
): Promise<string[]> => {
  const uncommitted = await readUncommittedSpecNames(specsDirectory, signal);

  const recencies: SpecRecency[] = await Promise.all(
    names.map(async (name) => {
      // Uncommitted files keep their mtime: the editor just wrote them, so it is meaningful.
      const committedAt =
        uncommitted === null || uncommitted.has(name)
          ? null
          : await readLastCommitTimeMs(specsDirectory, name, signal);

      let recency = committedAt;
      if (recency === null) {
        const fileStat = await stat(path.join(specsDirectory, name));
        recency = fileStat.mtimeMs;
      }

      return { name, recency };
    })
  );

  return recencies
    .toSorted(
      (left, right) =>
        right.recency - left.recency ||
        left.name.localeCompare(right.name)
    )
    .map((entry) => entry.name);
};

interface SpecCommand {
  name: string;
  description: string;
  pickerTitle: string;
  buildPrompt: (specPath: string) => string;
}

const registerSpecCommand = (host: OpenCodeCommandHost, command: SpecCommand): void => {
  host.registerCommand(command.name, {
    description: command.description,
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify(`/${command.name} requires an interactive UI`, "warning");
        return;
      }

      await ctx.waitForIdle();

      const specsDirectory = path.join(ctx.cwd, "specs");
      let specs: string[];

      try {
        const entries = await readdir(specsDirectory, { withFileTypes: true });
        const files = entries.filter((entry) => entry.isFile());

        specs = await orderSpecsByRecency(
          specsDirectory,
          files.map((entry) => entry.name),
          ctx.signal
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
      if (selected === undefined || selected === "") {
        return;
      }

      host.sendUserMessage(command.buildPrompt(`specs/${selected}`), {
        expandPromptTemplates: true,
      });
    },
  });
};

const registerCreateSpecCommand = (host: OpenCodeCommandHost): void => {
  host.registerCommand("create-spec", {
    description:
      "Capture a new idea in a text box and draft a spec via grill-with-docs and spec-planner",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/create-spec requires an interactive UI", "warning");
        return;
      }

      await ctx.waitForIdle();

      const rawIdea = await ctx.ui.input("What would you like to build?");
      if (rawIdea === undefined) {
        return;
      }

      const idea = rawIdea.trim();
      if (idea.length === 0) {
        return;
      }

      host.sendUserMessage(buildCreateSpecPrompt(idea), {
        expandPromptTemplates: true,
      });
    },
  });
};

export default Plugin.define({
  id: "spec-tools.tui",
  setup(context) {
    const location = context.location ?? context.data.location.default();
    const commandAbortController = new AbortController();
    let submittedPrompt: Promise<unknown> | undefined;
    const commands: Array<{
      name: string;
      description: string;
      handler: (args: string, context: CommandContext) => Promise<void>;
    }> = [];
    const commandContext: CommandContext = {
      cwd: location.directory,
      hasUI: true,
      signal: commandAbortController.signal,
      waitForIdle: async () => {
        await submittedPrompt;
        submittedPrompt = undefined;
      },
      ui: {
        input: async (title) =>
          context.ui.dialog.prompt({ title, placeholder: "Describe the idea" }),
        notify: (message, level) => {
          context.ui.toast.show({
            message,
            variant: level === "warning" ? "warning" : level,
          });
        },
        select: async (title, options) =>
          context.ui.dialog.select({
            title,
            options: options.map((option) => ({ title: option, value: option })),
          }),
      },
    };
    const host: OpenCodeCommandHost = {
      registerCommand: (name, command) => {
        commands.push({ name, ...command });
      },
      sendUserMessage: (prompt) => {
        submittedPrompt = (async () => {
          const route = context.ui.router.current();
          let sessionID: string;
          if (route.type === "session") {
            sessionID = route.sessionID;
            const session = await context.client.session.get({ sessionID });
            if (!session.model) {
              const build = await context.client.agent.get({ agentID: "build", location });
              if (!build.data.model) {
                throw new Error("Build agent has no configured model");
              }
              await context.client.session.switchAgent({ sessionID, agent: "build" });
              await context.client.session.switchModel({ sessionID, model: build.data.model });
            }
          } else {
            const build = await context.client.agent.get({ agentID: "build", location });
            if (!build.data.model) {
              throw new Error("Build agent has no configured model");
            }
            sessionID = (
              await context.client.session.create({
                location,
                agent: "build",
                model: build.data.model,
              })
            ).id;
          }

          if (route.type !== "session") {
            context.ui.router.navigate({ type: "session", sessionID });
          }

          const command =
            /^\/(?<name>[^\s]+)(?:\s+(?<arguments>[\s\S]*))?$/u.exec(
              prompt
            );
          if (command?.groups?.name) {
            await context.client.session.command({
              sessionID,
              name: command.groups.name,
              text: command.groups.arguments ?? "",
            });
            return;
          }
          await context.client.session.prompt({ sessionID, text: prompt });
        })().catch((error: unknown) => {
            context.ui.toast.show({
              message: `Could not submit spec prompt: ${error instanceof Error ? error.message : String(error)}`,
              variant: "error",
            });
          });
      },
    };

    registerCreateSpecCommand(host);
    registerSpecCommand(host, {
    buildPrompt: buildImplementationPrompt,
    description: "Choose a file from specs/ and ask the agent to implement it",
    name: "implement-spec",
    pickerTitle: "Choose a specification to implement",
  });
    registerSpecCommand(host, {
    buildPrompt: buildStackedImplementationPrompt,
    description:
      "Choose a file from specs/ and ask the agent to implement it as stacked PRs, one per deliverable",
    name: "implement-spec-stacked",
    pickerTitle: "Choose a specification to implement as a stack",
  });
    registerSpecCommand(host, {
    buildPrompt: buildScrubPrompt,
    description: "Choose a file from specs/ and ask the agent to refine it",
    name: "scrub-spec",
    pickerTitle: "Choose a specification to refine",
  });
    registerSpecCommand(host, {
    buildPrompt: buildSimplifyPrompt,
    description:
      "Choose a file from specs/ and ask the agent to propose a much simpler solution with 80% of the benefits",
    name: "simplify-spec",
    pickerTitle: "Choose a specification to simplify",
  });
    registerSpecCommand(host, {
    buildPrompt: buildAnnotationPrompt,
    description: "Choose a file from specs/ and annotate it with Plannotator",
    name: "spec-annotate",
    pickerTitle: "Choose a specification to annotate",
  });
    registerSpecCommand(host, {
    buildPrompt: buildBackgroundScrubPrompt,
    description:
      "Choose a file from specs/ and refine it in a background subagent",
    name: "scrub-spec-bg",
      pickerTitle: "Choose a specification to refine in the background",
    });

    const removeCommandSlot = context.ui.slot({
      append: "app",
      render: () => {
        context.keymap.layer(() => ({
          mode: "global",
          commands: commands.map((command) => ({
            id: `spec-tools.${command.name}`,
            title: command.description,
            group: "Spec tools",
            palette: true,
            slash: { name: command.name },
            run: async (input) => command.handler(input ?? "", commandContext),
          })),
          bindings: [],
        }));
        return null;
      },
    });

    return () => {
      commandAbortController.abort();
      removeCommandSlot();
    };
  },
});
