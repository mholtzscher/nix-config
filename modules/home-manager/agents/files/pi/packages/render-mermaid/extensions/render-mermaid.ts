import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";
import fs from "node:fs";

function looksLikeMermaid(diagram: string) {
	return /^(?:\s|%%.*\n)*(?:flowchart|graph|sequenceDiagram|stateDiagram(?:-v2)?)/m.test(diagram);
}

async function renderWithMerman(diagram: string, color: boolean) {
	const command = fs.existsSync("/etc/profiles/per-user/michael/bin/bun") ? "/etc/profiles/per-user/michael/bin/bun" : "bun";
	const args = ["x", "@kitlangton/merman", ...(color ? [] : ["--no-color"] )];

	return await new Promise<string>((resolve, reject) => {
		const child = spawn(command, args, {
			stdio: ["pipe", "pipe", "pipe"],
		});

		let stdout = "";
		let stderr = "";

		child.stdout.on("data", (chunk) => {
			stdout += String(chunk);
		});

		child.stderr.on("data", (chunk) => {
			stderr += String(chunk);
		});

		child.on("error", (error) => {
			if ((error as NodeJS.ErrnoException).code === "ENOENT") {
				reject(new Error("render_mermaid could not find bun on PATH."));
				return;
			}
			reject(error);
		});

		child.on("close", (code) => {
			if (code === 0) {
				resolve(stdout.trimEnd());
				return;
			}

			reject(new Error(stderr.trim() || `merman exited with code ${code}`));
		});

		child.stdin.write(diagram);
		child.stdin.end();
	});
}

const renderMermaidTool = defineTool({
	name: "render_mermaid",
	label: "Render Mermaid",
	description:
		"Render Mermaid flowchart/graph, sequenceDiagram, and stateDiagram-v2 diagrams into terminal-friendly box drawing output.",
	promptSnippet: "Render Mermaid diagrams into terminal-friendly previews.",
	promptGuidelines: [
		"Use render_mermaid after writing a Mermaid diagram when the user would benefit from seeing a rendered preview.",
		"Pass the raw Mermaid source exactly as written by the agent to render_mermaid.",
	],
	parameters: Type.Object({
		diagram: Type.String({
			description:
				"The full Mermaid diagram source, including the leading flowchart/sequenceDiagram/stateDiagram-v2 line.",
		}),
		color: Type.Optional(
			Type.Boolean({
				description: "Whether to include ANSI colors in the rendered output. Defaults to false.",
			}),
		),
	}),
	async execute(_toolCallId, params) {
		const diagram = params.diagram.trim();

		if (!diagram) {
			throw new Error("diagram must not be empty");
		}

		if (!looksLikeMermaid(diagram)) {
			throw new Error(
				"Unsupported Mermaid input. render_mermaid currently expects a flowchart, graph, sequenceDiagram, or stateDiagram-v2 diagram.",
			);
		}

		const rendered = await renderWithMerman(diagram, params.color ?? false);

		return {
			content: [{ type: "text", text: rendered }],
			details: {
				rendered,
				color: params.color ?? false,
				originalDiagram: diagram,
			},
		};
	},
});

export default function renderMermaidExtension(pi: ExtensionAPI) {
	pi.registerTool(renderMermaidTool);
}
