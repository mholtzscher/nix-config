import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const PROVIDER = "openai-codex";
const STATUS_KEY = "codex-weekly-usage";
const USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";
const REQUEST_TIMEOUT_MS = 15 * 1000;

type UsageWindow = {
	used_percent?: unknown;
	limit_window_seconds?: unknown;
	reset_at?: unknown;
};

type UsageResponse = {
	rate_limit?: {
		primary_window?: UsageWindow;
		secondary_window?: UsageWindow;
	};
};

export default function codexWeeklyUsage(pi: ExtensionAPI) {
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
			const headers = await getAuthHeaders(ctx);
			if (!headers) {
				ctx.ui.setStatus(STATUS_KEY, undefined);
				return;
			}

			const response = await fetchWithTimeout(USAGE_URL, { headers }, REQUEST_TIMEOUT_MS);
			if (!response.ok) throw new Error(`HTTP ${response.status}`);

			const usage = (await response.json()) as UsageResponse;
			const weekly = findWeeklyWindow(usage);
			if (!weekly) throw new Error("weekly window missing");

			if (active && currentRequest === requestId) {
				ctx.ui.setStatus(STATUS_KEY, formatWeeklyUsage(weekly));
			}
		} catch {
			if (active && currentRequest === requestId) {
				ctx.ui.setStatus(STATUS_KEY, "Codex wk: unavailable");
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

async function getAuthHeaders(ctx: ExtensionContext): Promise<Record<string, string> | undefined> {
	const models = [ctx.model, ...ctx.modelRegistry.getAvailable(), ...ctx.modelRegistry.getAll()];
	const seen = new Set<string>();

	for (const model of models) {
		if (!model || model.provider !== PROVIDER || seen.has(model.id)) continue;
		seen.add(model.id);

		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
		if (!auth.ok) continue;

		const headers = { ...(auth.headers ?? {}) };
		if (!hasHeader(headers, "Authorization") && auth.apiKey) {
			headers.Authorization = `Bearer ${auth.apiKey}`;
		}
		if (hasHeader(headers, "Authorization")) return headers;
	}

	return undefined;
}

function findWeeklyWindow(response: UsageResponse): UsageWindow | undefined {
	const rateLimit = response.rate_limit;
	if (!rateLimit) return undefined;

	const windows = [rateLimit.primary_window, rateLimit.secondary_window].filter(
		(window): window is UsageWindow => window !== undefined,
	);
	return (
		windows.find((window) => numberValue(window.limit_window_seconds) === 7 * 24 * 60 * 60) ??
		rateLimit.secondary_window
	);
}

function formatWeeklyUsage(window: UsageWindow): string {
	const used = numberValue(window.used_percent);
	if (used === undefined) throw new Error("weekly usage missing");

	const remaining = Math.max(0, Math.min(100, 100 - used));
	const resetAt = numberValue(window.reset_at);
	const reset = resetAt === undefined ? "" : ` · ${formatReset(resetAt)}`;
	return `CX ${remaining.toFixed(0)}%${reset}`;
}

function formatReset(epochSeconds: number): string {
	const remainingMinutes = Math.max(0, Math.floor((epochSeconds * 1000 - Date.now()) / 60_000));
	const days = Math.floor(remainingMinutes / (24 * 60));
	const hours = Math.floor((remainingMinutes % (24 * 60)) / 60);
	if (days > 0) return `${days}d${hours > 0 ? `${hours}h` : ""}`;
	if (hours > 0) return `${hours}h`;
	return `${remainingMinutes}m`;
}

function numberValue(value: unknown): number | undefined {
	if (typeof value === "number" && Number.isFinite(value)) return value;
	if (typeof value === "string" && value.trim() !== "") {
		const parsed = Number(value);
		if (Number.isFinite(parsed)) return parsed;
	}
	return undefined;
}

function hasHeader(headers: Record<string, string>, name: string): boolean {
	return Object.keys(headers).some((header) => header.toLowerCase() === name.toLowerCase());
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
