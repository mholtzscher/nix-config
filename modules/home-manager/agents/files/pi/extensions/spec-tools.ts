import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readdir, stat } from "node:fs/promises";
import { join } from "node:path";

function buildImplementationPrompt(specPath: string): string {
	return `Implement @${specPath} end-to-end.

Operate autonomously:
1. Read the specification completely and follow all repository instructions.
2. Use available subagents for bounded discovery, implementation, or validation work so the main context stays focused. Prefer foreground agents over background agents.
3. Keep a concise log of assumptions and include it in the PR description and final report. Do not create a separate assumptions file unless the specification requests one.
4. Implement the smallest complete solution and run all relevant local validation.
5. Create or use an appropriate branch, commit and push the changes, and publish a pull request.
6. Monitor all required GitHub Actions checks until they finish successfully. If a check fails, investigate it, fix the issue, validate locally, push the update, and repeat until the required checks pass.

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

function buildBackgroundScrubPrompt(specPath: string): string {
	const prompt = `Before editing, read and follow the unslop skill at ~/.pi/agent/skills/pstack/unslop/SKILL.md.\n\n${buildScrubTaskPrompt(specPath)}`;

	return `Call the Agent tool exactly once with these arguments:

- agent: "general-purpose"
- description: "Scrub ${specPath}"
- run_in_background: true
- prompt: ${JSON.stringify(prompt)}

Do not scrub the specification yourself. After the Agent tool confirms the background spawn, stop.`;
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
				const files = (await readdir(specsDirectory, { withFileTypes: true }))
					.filter((entry) => entry.isFile());
				const modifiedFiles = await Promise.all(files.map(async (entry) => ({
					name: entry.name,
					modifiedAt: (await stat(join(specsDirectory, entry.name))).mtimeMs,
				})));

				specs = modifiedFiles
					.sort((left, right) => right.modifiedAt - left.modifiedAt || left.name.localeCompare(right.name))
					.map((file) => file.name);
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
		name: "scrub-spec",
		description: "Choose a file from specs/ and ask the agent to refine it",
		pickerTitle: "Choose a specification to refine",
		buildPrompt: buildScrubPrompt,
	});
	registerSpecCommand(pi, {
		name: "scrub-spec-bg",
		description: "Choose a file from specs/ and refine it in a background subagent",
		pickerTitle: "Choose a specification to refine in the background",
		buildPrompt: buildBackgroundScrubPrompt,
	});
}
