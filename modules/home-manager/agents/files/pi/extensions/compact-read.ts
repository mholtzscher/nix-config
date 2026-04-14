/**
 * Compact read renderer for pi.
 *
 * Project-local extension that keeps the built-in `read` behavior, but renders
 * results in a much smaller form by default:
 * - collapsed: show a short summary with line count and truncation info
 * - expanded: show a small preview instead of the full file contents
 *
 * Usage:
 *   1. Start pi in this repo, or run `/reload` if pi is already open.
 *   2. Use `Ctrl+O` on a read tool result to expand/collapse the preview.
 */

import type { ExtensionAPI, ReadToolDetails } from "@mariozechner/pi-coding-agent";
import { createReadTool, keyHint } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";

const PREVIEW_LINES = 8;

export default function (pi: ExtensionAPI) {
	const originalRead = createReadTool(process.cwd());
	const renderOriginalResult = (originalRead as any).renderResult as
		| ((result: any, options: any, theme: any, context: any) => Text)
		| undefined;

	pi.registerTool({
		...originalRead,

		renderCall(args, theme, _context) {
			let text = theme.fg("toolTitle", theme.bold("read "));
			text += theme.fg("accent", args.path);

			const range: string[] = [];
			if (args.offset) range.push(`offset=${args.offset}`);
			if (args.limit) range.push(`limit=${args.limit}`);
			if (range.length > 0) {
				text += theme.fg("dim", ` (${range.join(", ")})`);
			}

			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded, isPartial }, theme, context) {
			if (isPartial) {
				return new Text(theme.fg("warning", "Reading..."), 0, 0);
			}

			const content = result.content[0];
			const details = result.details as ReadToolDetails | undefined;

			if (content?.type === "image") {
				return renderOriginalResult
					? renderOriginalResult(result, { expanded, isPartial }, theme, context)
					: new Text(theme.fg("success", "Image loaded"), 0, 0);
			}

			if (content?.type !== "text") {
				return new Text(theme.fg("error", "No readable text content"), 0, 0);
			}

			if (content.text.startsWith("Error")) {
				return new Text(theme.fg("error", content.text.split("\n")[0] ?? "Read failed"), 0, 0);
			}

			const lines = content.text.split("\n");
			const lineCount = lines.length;
			const preview = lines.slice(0, PREVIEW_LINES);

			let text = theme.fg("success", `${lineCount} line${lineCount === 1 ? "" : "s"}`);
			if (details?.truncation?.truncated) {
				const totalLines = details.truncation.totalLines;
				if (typeof totalLines === "number") {
					text += theme.fg("warning", ` (truncated from ${totalLines} lines)`);
				} else {
					text += theme.fg("warning", " (truncated)");
				}
			}

			if (!expanded) {
				text += theme.fg("dim", ` (${keyHint("app.tools.expand", "to preview")})`);
				return new Text(text, 0, 0);
			}

			for (const line of preview) {
				text += `\n${theme.fg("dim", line)}`;
			}

			if (lineCount > PREVIEW_LINES) {
				text += `\n${theme.fg("muted", `... ${lineCount - PREVIEW_LINES} more lines`)}`;
			}

			return new Text(text, 0, 0);
		},
	});
}
