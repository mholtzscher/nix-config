import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readdir, stat } from "node:fs/promises";
import { join } from "node:path";

function buildImplementationPrompt(specPath: string): string {
	return `Implement @${specPath} end-to-end.

Operate autonomously:
1. Read the specification completely and follow all repository instructions.
2. Use available subagents for bounded discovery, implementation, or validation work so the main context stays focused.
3. Keep a concise log of assumptions and include it in the PR description and final report. Do not create a separate assumptions file unless the specification requests one.
4. Implement the smallest complete solution and run all relevant local validation.
5. Create or use an appropriate branch, commit and push the changes, and publish a pull request.
6. Monitor all required GitHub Actions checks until they finish successfully. If a check fails, investigate it, fix the issue, validate locally, push the update, and repeat until the required checks pass.

Only stop to ask for help when blocked by missing credentials or permissions, or when an ambiguity could cause a destructive or materially different outcome.`;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("implement-spec", {
		description: "Choose a file from specs/ and ask the agent to implement it",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("/implement-spec requires an interactive UI", "warning");
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

			const selected = await ctx.ui.select("Choose a specification to implement", specs);
			if (!selected) return;

			const specPath = `specs/${selected}`;
			pi.sendUserMessage(buildImplementationPrompt(specPath));
		},
	});
}
