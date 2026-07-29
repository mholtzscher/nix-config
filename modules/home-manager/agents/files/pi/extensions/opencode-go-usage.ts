import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "opencode-go-usage";
const REQUEST_TIMEOUT_MS = 15 * 1000;
const USER_AGENT =
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Gecko/20100101 Firefox/148.0";

type UsageWindow = {
	usagePercent: number;
	resetInSec: number;
};

type Usage = Partial<Record<"rolling" | "weekly" | "monthly", UsageWindow>>;

export default function opencodeGoUsage(pi: ExtensionAPI) {
	let requestId = 0;
	let active = false;

	const stop = () => {
		active = false;
		requestId += 1;
	};

	const refresh = async (ctx: ExtensionContext) => {
		if (!active) return;
		const currentRequest = ++requestId;

		try {
			const workspaceId = process.env.OPENCODE_GO_WORKSPACE_ID;
			const authCookie = process.env.OPENCODE_GO_AUTH_COOKIE;
			if (!workspaceId || !authCookie) {
				ctx.ui.setStatus(STATUS_KEY, undefined);
				return;
			}

			const url = `https://opencode.ai/workspace/${encodeURIComponent(workspaceId)}/go`;
			const response = await fetchWithTimeout(
				url,
				{
					headers: {
						Accept: "text/html",
						Cookie: authCookieHeader(authCookie),
						"User-Agent": USER_AGENT,
					},
				},
				REQUEST_TIMEOUT_MS,
			);
			if (!response.ok) throw new Error(`HTTP ${response.status}`);

			const usage = parseUsage(await response.text());
			if (!usage.rolling && !usage.weekly && !usage.monthly) {
				throw new Error("usage windows missing");
			}

			if (active && currentRequest === requestId) {
				ctx.ui.setStatus(STATUS_KEY, formatUsage(usage));
			}
		} catch {
			if (active && currentRequest === requestId) {
				ctx.ui.setStatus(STATUS_KEY, "GO: unavailable");
			}
		}
	};

	pi.on("session_start", (_event, ctx) => {
		active = true;
		void refresh(ctx);
	});

	pi.on("agent_settled", (_event, ctx) => {
		void refresh(ctx);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		stop();
		ctx.ui.setStatus(STATUS_KEY, undefined);
	});
}

function authCookieHeader(value: string): string {
	const authCookie = value
		.split(";")
		.map((part) => part.trim())
		.find((part) => part.startsWith("auth="));
	return authCookie ?? `auth=${value}`;
}

function parseUsage(html: string): Usage {
	const usage: Usage = {
		rolling: parseSsrWindow(html, "rolling"),
		weekly: parseSsrWindow(html, "weekly"),
		monthly: parseSsrWindow(html, "monthly"),
	};

	if (usage.rolling || usage.weekly || usage.monthly) return usage;
	return parseDataSlots(html);
}

function parseSsrWindow(html: string, name: keyof Usage): UsageWindow | undefined {
	const object = html.match(new RegExp(`${name}Usage:\\$R\\[\\d+\\]=\\{([^}]*)\\}`))?.[1];
	if (!object) return undefined;

	const usagePercent = numberField(object, "usagePercent");
	const resetInSec = numberField(object, "resetInSec");
	if (usagePercent === undefined || resetInSec === undefined) return undefined;
	return { usagePercent, resetInSec };
}

function numberField(object: string, field: string): number | undefined {
	const match = object.match(new RegExp(`${field}:(-?\\d+(?:\\.\\d+)?)`));
	if (!match) return undefined;
	const value = Number(match[1]);
	return Number.isFinite(value) ? value : undefined;
}

function parseDataSlots(html: string): Usage {
	const usage: Usage = {};

	for (const item of html.split(/data-slot="usage-item"/).slice(1)) {
		const label = item.match(/data-slot="usage-label">([^<]+)</)?.[1]?.toLowerCase();
		const percent = item.match(/data-slot="usage-value">[^0-9]*(\d+(?:\.\d+)?)/)?.[1];
		const reset = item.match(/data-slot="(reset-time|reset-now)">([\s\S]*?)<\/span>/);
		if (!label || !percent || !reset) continue;

		const name = (["rolling", "weekly", "monthly"] as const).find((candidate) =>
			label.includes(candidate),
		);
		const usagePercent = Number(percent);
		const resetInSec = reset[1] === "reset-now" ? 0 : parseDuration(stripHtml(reset[2]));
		if (!name || !Number.isFinite(usagePercent) || resetInSec === undefined) continue;
		usage[name] = { usagePercent, resetInSec };
	}

	return usage;
}

function stripHtml(value: string): string {
	return value.replace(/<[^>]*>/g, " ").replace(/Resets?\s+in/i, "").replace(/\s+/g, " ").trim();
}

function parseDuration(value: string): number | undefined {
	let seconds = 0;
	let matched = false;
	const units = { day: 86_400, hour: 3_600, minute: 60, second: 1 };

	for (const [unit, multiplier] of Object.entries(units)) {
		const amount = value.match(new RegExp(`(\\d+(?:\\.\\d+)?)\\s*${unit}s?`, "i"))?.[1];
		if (!amount) continue;
		matched = true;
		seconds += Number(amount) * multiplier;
	}

	return matched && Number.isFinite(seconds) ? seconds : undefined;
}

function formatUsage(usage: Usage): string {
	const windows = [
		["R", usage.rolling],
		["W", usage.weekly],
		["M", usage.monthly],
	] as const;
	const formatted = windows.flatMap(([label, window]) =>
		window ? [`${label}${remainingPercent(window)}%`] : [],
	);
	return `GO ${formatted.join(" ")}`;
}

function remainingPercent(window: UsageWindow): string {
	return Math.max(0, Math.min(100, 100 - window.usagePercent)).toFixed(0);
}

async function fetchWithTimeout(
	url: string,
	init: RequestInit,
	timeoutMs: number,
): Promise<Response> {
	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), timeoutMs);
	try {
		return await fetch(url, { ...init, signal: controller.signal });
	} finally {
		clearTimeout(timeout);
	}
}
