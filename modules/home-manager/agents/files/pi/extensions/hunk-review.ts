/**
 * /hr
 *
 * Ensures Hunk is running in a Zellij tab named `hunk-review`, then asks pi
 * to perform a guided code review using the hunk-review skill.
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

const HUNK_TAB_NAME = "hunk-review";
const HUNK_PANE_NAME = "hunk";
const HUNK_READY_TIMEOUT_MS = 10_000;
const HUNK_READY_POLL_MS = 500;

const GUIDED_REVIEW_PROMPT = "/skill:hunk-review Perform a guided code review.";

type ZellijPane = {
	id?: number;
	title?: string;
	tab_id?: number;
	tab_name?: string;
	pane_command?: string;
	terminal_command?: string;
	exited?: boolean;
};

type ZellijTabInfo = {
	tab_id?: number;
};

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function parseZellijPanes(stdout: string): ZellijPane[] {
	const parsed: unknown = JSON.parse(stdout);
	if (!Array.isArray(parsed)) {
		throw new Error("zellij list-panes returned non-array JSON");
	}

	return parsed.filter(isRecord).map((pane) => ({
		id: typeof pane.id === "number" ? pane.id : undefined,
		title: typeof pane.title === "string" ? pane.title : undefined,
		tab_id: typeof pane.tab_id === "number" ? pane.tab_id : undefined,
		tab_name: typeof pane.tab_name === "string" ? pane.tab_name : undefined,
		pane_command: typeof pane.pane_command === "string" ? pane.pane_command : undefined,
		terminal_command: typeof pane.terminal_command === "string" ? pane.terminal_command : undefined,
		exited: typeof pane.exited === "boolean" ? pane.exited : undefined,
	}));
}

function parseZellijTabInfo(stdout: string): ZellijTabInfo {
	const parsed: unknown = JSON.parse(stdout);
	if (!isRecord(parsed)) {
		throw new Error("zellij current-tab-info returned non-object JSON");
	}

	return {
		tab_id: typeof parsed.tab_id === "number" ? parsed.tab_id : undefined,
	};
}

function paneLooksLikeRunningHunk(pane: ZellijPane): boolean {
	if (pane.exited === true) return false;

	const commandText = [pane.pane_command, pane.terminal_command, pane.title]
		.filter((value): value is string => typeof value === "string" && value.length > 0)
		.join(" ");

	return /(^|[\s/])hunk($|[\s/.:-])/.test(commandText);
}

async function sleep(ms: number): Promise<void> {
	await new Promise((resolve) => setTimeout(resolve, ms));
}

async function getCurrentZellijTabId(pi: ExtensionAPI): Promise<number | undefined> {
	const result = await pi.exec("zellij", ["action", "current-tab-info", "--json"], { timeout: 5_000 });
	if (result.code !== 0) return undefined;

	try {
		return parseZellijTabInfo(result.stdout).tab_id;
	} catch {
		return undefined;
	}
}

async function ensureHunkRunning(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<boolean> {
	if (!process.env.ZELLIJ) {
		ctx.ui.notify("Not inside Zellij; cannot open Hunk review tab.", "error");
		return false;
	}

	const listResult = await pi.exec("zellij", ["action", "list-panes", "-j", "-c", "-s", "-t"], {
		timeout: 5_000,
	});
	if (listResult.code !== 0) {
		ctx.ui.notify(`Could not inspect Zellij panes: ${listResult.stderr || listResult.stdout}`.trim(), "error");
		return false;
	}

	let panes: ZellijPane[];
	try {
		panes = parseZellijPanes(listResult.stdout);
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		ctx.ui.notify(`Could not parse Zellij pane list: ${message}`, "error");
		return false;
	}

	const hunkTabPanes = panes.filter((pane) => pane.tab_name === HUNK_TAB_NAME);
	const hunkRunning = hunkTabPanes.some(paneLooksLikeRunningHunk);
	if (hunkRunning) {
		return true;
	}

	if (hunkTabPanes.length > 0) {
		const tabId = hunkTabPanes.find((pane) => typeof pane.tab_id === "number")?.tab_id;
		if (tabId === undefined) {
			ctx.ui.notify("Found hunk-review tab but could not determine its Zellij tab id.", "error");
			return false;
		}

		const runResult = await pi.exec(
			"zellij",
			["run", "--tab-id", String(tabId), "--cwd", ctx.cwd, "--name", HUNK_PANE_NAME, "--", "hunk", "diff", "HEAD"],
			{ timeout: 5_000 },
		);
		if (runResult.code !== 0) {
			ctx.ui.notify(`Could not relaunch Hunk: ${runResult.stderr || runResult.stdout}`.trim(), "error");
			return false;
		}
		return true;
	}

	const previousTabId = await getCurrentZellijTabId(pi);
	const newTabResult = await pi.exec(
		"zellij",
		["action", "new-tab", "-n", HUNK_TAB_NAME, "--cwd", ctx.cwd, "--", "hunk", "diff", "HEAD"],
		{ timeout: 5_000 },
	);
	if (previousTabId !== undefined && newTabResult.code === 0) {
		await pi.exec("zellij", ["action", "go-to-tab-by-id", String(previousTabId)], { timeout: 5_000 });
	}
	if (newTabResult.code !== 0) {
		ctx.ui.notify(`Could not open Hunk tab: ${newTabResult.stderr || newTabResult.stdout}`.trim(), "error");
		return false;
	}

	return true;
}

async function waitForHunkSession(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<boolean> {
	const deadline = Date.now() + HUNK_READY_TIMEOUT_MS;
	let lastError = "";

	while (Date.now() < deadline) {
		const result = await pi.exec("hunk", ["session", "get", "--repo", ctx.cwd, "--json"], {
			timeout: 2_000,
		});
		if (result.code === 0) {
			return true;
		}

		lastError = (result.stderr || result.stdout).trim();
		await sleep(HUNK_READY_POLL_MS);
	}

	ctx.ui.notify(
		`Hunk was launched, but no live Hunk session appeared for this repo.${lastError ? ` Last error: ${lastError}` : ""}`,
		"error",
	);
	return false;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("hr", {
		description: "Open Hunk and start a guided Hunk review",
		handler: async (_args, ctx) => {
			const hunkRunning = await ensureHunkRunning(pi, ctx);
			if (!hunkRunning) return;

			const hunkReady = await waitForHunkSession(pi, ctx);
			if (!hunkReady) return;

			pi.sendUserMessage(GUIDED_REVIEW_PROMPT);
		},
	});
}
