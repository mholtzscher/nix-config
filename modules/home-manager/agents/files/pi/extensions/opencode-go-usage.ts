import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const PROVIDER = "opencode-go";
const STATUS_KEY = "opencode-go-usage";
const REQUEST_TIMEOUT_MS = 15 * 1000;

type UsageWindow = {
	percent: number;
	resetsAt: string;
};

type Usage = Partial<Record<"rolling" | "weekly" | "monthly", UsageWindow>>;

type UsageResponse = {
	usage?: Usage;
};

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
			const apiKey = await getApiKey(ctx);
			if (!apiKey) {
				ctx.ui.setStatus(STATUS_KEY, undefined);
				return;
			}

			const response = await fetchWithTimeout(
				"https://opencode.ai/zen/go/v1/usage",
				{
					headers: {
						Accept: "application/json",
						Authorization: `Bearer ${apiKey}`,
					},
				},
				REQUEST_TIMEOUT_MS,
			);
			if (!response.ok) throw new Error(`HTTP ${response.status}`);

			const usage = parseUsage(await response.json());
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

async function getApiKey(ctx: ExtensionContext): Promise<string | undefined> {
	const models = [ctx.model, ...ctx.modelRegistry.getAvailable(), ...ctx.modelRegistry.getAll()];

	for (const model of models) {
		if (!model || model.provider !== PROVIDER) continue;
		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
		if (auth.ok && auth.apiKey) return auth.apiKey;
	}

	return process.env.OPENCODE_API_KEY;
}

function parseUsage(response: unknown): Usage {
	const usage = (response as UsageResponse).usage;
	if (!usage) return {};

	return Object.fromEntries(
		Object.entries(usage).filter(
			([name, window]) =>
				["rolling", "weekly", "monthly"].includes(name) &&
				isUsageWindow(window),
		),
	) as Usage;
}

function isUsageWindow(value: unknown): value is UsageWindow {
	return (
		typeof value === "object" &&
		value !== null &&
		typeof (value as UsageWindow).percent === "number" &&
		Number.isFinite((value as UsageWindow).percent) &&
		typeof (value as UsageWindow).resetsAt === "string"
	);
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
	return Math.max(0, Math.min(100, 100 - window.percent)).toFixed(0);
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
