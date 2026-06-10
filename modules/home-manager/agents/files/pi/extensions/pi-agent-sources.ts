import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
	fuzzyFilter,
	type AutocompleteItem,
	type AutocompleteProvider,
	type AutocompleteSuggestions,
} from "@earendil-works/pi-tui";
import { existsSync } from "node:fs";
import { mkdir, readdir, readFile, rm, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, isAbsolute, join, resolve } from "node:path";

const CONFIG_KEY = "pi-agent-sources";
const DEFAULT_REPO_CACHE_DIR = "pi-agent-sources/repos";
const MAX_SCAN_ENTRIES = 2_000;
const MAX_SUGGESTIONS = 20;
const GIT_TIMEOUT_MS = 60_000;

const RESERVED_CONFIG_KEYS = new Set(["sources", "cacheDir", "autoUpdate"]);

type RawSource =
	| string
	| {
			path?: string;
			repository?: string;
			branch?: string;
			description?: string;
			hidden?: boolean;
	  };

type SourceKind = "path" | "repository";

type SourceSpec = {
	alias: string;
	kind: SourceKind;
	path?: string;
	repository?: string;
	branch?: string;
	description?: string;
	hidden: boolean;
	settingsPath: string;
};

type ResolvedSource = SourceSpec & {
	rootPath: string;
	entriesPromise?: Promise<SourceEntry[]>;
};

type SourceEntry = {
	path: string;
	isDirectory: boolean;
};

type LoadResult = {
	sources: ResolvedSource[];
	errors: string[];
};

type LoadedConfig = {
	sources: SourceSpec[];
	cacheDir?: string;
	autoUpdate?: boolean;
	errors: string[];
};

let activeSources: ResolvedSource[] = [];
let activeErrors: string[] = [];
let autocompleteInstalled = false;

function isObject(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function expandHomePath(path: string): string {
	if (path === "~") return homedir();
	if (path.startsWith("~/")) return join(homedir(), path.slice(2));
	return path;
}

function resolveConfigPath(value: string, baseDir: string): string {
	const expanded = expandHomePath(value);
	return isAbsolute(expanded) ? expanded : resolve(baseDir, expanded);
}

function normalizeSlashes(value: string): string {
	return value.replace(/\\/g, "/");
}

function validateAlias(alias: string): string | undefined {
	if (!alias) return "alias cannot be empty";
	if (/[\/\s`,]/.test(alias)) {
		return "alias cannot contain '/', whitespace, backticks, or commas";
	}
	return undefined;
}

function looksLikeRepository(value: string, baseDir: string): boolean {
	const resolvedLocalPath = resolveConfigPath(value, baseDir);
	if (existsSync(resolvedLocalPath)) return false;

	return (
		/^(https?|ssh|git):\/\//.test(value) ||
		value.startsWith("git@") ||
		/^github\.com\/[^/\s]+\/[^/\s]+(?:\.git)?$/.test(value) ||
		/^[^/\s]+\/[^/\s]+$/.test(value)
	);
}

function normalizeRepository(value: string): string {
	if (/^[^/\s]+\/[^/\s]+$/.test(value)) {
		return `https://github.com/${value}.git`;
	}
	if (/^github\.com\/[^/\s]+\/[^/\s]+(?:\.git)?$/.test(value)) {
		return `https://${value}${value.endsWith(".git") ? "" : ".git"}`;
	}
	return value;
}

function parseSource(alias: string, raw: RawSource, baseDir: string, settingsPath: string): SourceSpec | string {
	const aliasError = validateAlias(alias);
	if (aliasError) return `${settingsPath}: ${CONFIG_KEY}.${alias}: ${aliasError}`;

	if (typeof raw === "string") {
		if (looksLikeRepository(raw, baseDir)) {
			return {
				alias,
				kind: "repository",
				repository: normalizeRepository(raw),
				hidden: false,
				settingsPath,
			};
		}

		return {
			alias,
			kind: "path",
			path: resolveConfigPath(raw, baseDir),
			hidden: false,
			settingsPath,
		};
	}

	if (!isObject(raw)) {
		return `${settingsPath}: ${CONFIG_KEY}.${alias}: source must be a string or object`;
	}

	const pathValue = typeof raw.path === "string" ? raw.path : undefined;
	const repositoryValue = typeof raw.repository === "string" ? raw.repository : undefined;
	if (!pathValue && !repositoryValue) {
		return `${settingsPath}: ${CONFIG_KEY}.${alias}: expected either path or repository`;
	}
	if (pathValue && repositoryValue) {
		return `${settingsPath}: ${CONFIG_KEY}.${alias}: path and repository are mutually exclusive`;
	}

	return {
		alias,
		kind: pathValue ? "path" : "repository",
		path: pathValue ? resolveConfigPath(pathValue, baseDir) : undefined,
		repository: repositoryValue ? normalizeRepository(repositoryValue) : undefined,
		branch: typeof raw.branch === "string" ? raw.branch : undefined,
		description: typeof raw.description === "string" ? raw.description : undefined,
		hidden: raw.hidden === true,
		settingsPath,
	};
}

async function readSettings(path: string): Promise<Record<string, unknown> | undefined> {
	try {
		return JSON.parse(await readFile(path, "utf8")) as Record<string, unknown>;
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined;
		throw error;
	}
}

function sourceMapFromConfig(rawConfig: Record<string, unknown>): Record<string, RawSource> {
	if (isObject(rawConfig.sources)) {
		return rawConfig.sources as Record<string, RawSource>;
	}

	const sources: Record<string, RawSource> = {};
	for (const [key, value] of Object.entries(rawConfig)) {
		if (RESERVED_CONFIG_KEYS.has(key)) continue;
		sources[key] = value as RawSource;
	}
	return sources;
}

async function loadConfigFromSettings(settingsPath: string, baseDir: string): Promise<LoadedConfig> {
	try {
		const settings = await readSettings(settingsPath);
		const rawConfig = settings?.[CONFIG_KEY];
		if (!isObject(rawConfig)) {
			return { sources: [], errors: [] };
		}

		const errors: string[] = [];
		const sources: SourceSpec[] = [];
		for (const [alias, rawSource] of Object.entries(sourceMapFromConfig(rawConfig))) {
			const parsed = parseSource(alias, rawSource, baseDir, settingsPath);
			if (typeof parsed === "string") {
				errors.push(parsed);
			} else {
				sources.push(parsed);
			}
		}

		const cacheDir = typeof rawConfig.cacheDir === "string" ? resolveConfigPath(rawConfig.cacheDir, baseDir) : undefined;
		const autoUpdate = typeof rawConfig.autoUpdate === "boolean" ? rawConfig.autoUpdate : undefined;
		return { sources, cacheDir, autoUpdate, errors };
	} catch (error) {
		return {
			sources: [],
			errors: [`${settingsPath}: failed to read ${CONFIG_KEY}: ${(error as Error).message}`],
		};
	}
}

async function loadConfiguredSources(cwd: string, projectTrusted: boolean): Promise<LoadedConfig> {
	const agentDir = getAgentDir();
	const projectPiDir = join(cwd, ".pi");
	const global = await loadConfigFromSettings(join(agentDir, "settings.json"), agentDir);
	const project = projectTrusted
		? await loadConfigFromSettings(join(projectPiDir, "settings.json"), projectPiDir)
		: { sources: [], errors: [] };

	const byAlias = new Map<string, SourceSpec>();
	for (const source of global.sources) byAlias.set(source.alias, source);
	for (const source of project.sources) byAlias.set(source.alias, source);

	return {
		sources: [...byAlias.values()],
		cacheDir: project.cacheDir ?? global.cacheDir ?? join(agentDir, DEFAULT_REPO_CACHE_DIR),
		autoUpdate: project.autoUpdate ?? global.autoUpdate ?? false,
		errors: [...global.errors, ...project.errors],
	};
}

function safeCacheName(alias: string): string {
	return alias.replace(/[^A-Za-z0-9._-]/g, "_");
}

async function ensureLocalDirectory(source: SourceSpec): Promise<ResolvedSource> {
	const path = source.path!;
	const info = await stat(path);
	if (!info.isDirectory()) {
		throw new Error(`${path} is not a directory`);
	}
	return { ...source, rootPath: path };
}

async function runGit(pi: ExtensionAPI, args: string[], cwd: string): Promise<void> {
	const result = await pi.exec("git", args, { cwd, timeout: GIT_TIMEOUT_MS });
	if (result.code !== 0) {
		throw new Error((result.stderr || result.stdout || `git exited ${result.code}`).trim());
	}
}

async function ensureRepository(pi: ExtensionAPI, source: SourceSpec, cacheDir: string, autoUpdate: boolean): Promise<ResolvedSource> {
	const repository = source.repository!;
	const rootPath = join(cacheDir, safeCacheName(source.alias));
	await mkdir(cacheDir, { recursive: true });

	if (!existsSync(join(rootPath, ".git"))) {
		if (existsSync(rootPath)) {
			await rm(rootPath, { recursive: true, force: true });
		}
		const args = ["clone", "--depth", "1"];
		if (source.branch) args.push("--branch", source.branch);
		args.push(repository, rootPath);
		await runGit(pi, args, cacheDir);
	} else if (autoUpdate) {
		if (source.branch) {
			await runGit(pi, ["fetch", "--depth", "1", "origin", source.branch], rootPath);
			await runGit(pi, ["checkout", source.branch], rootPath);
			await runGit(pi, ["reset", "--hard", `origin/${source.branch}`], rootPath);
		} else {
			await runGit(pi, ["pull", "--ff-only"], rootPath);
		}
	}

	return { ...source, rootPath };
}

async function resolveSources(pi: ExtensionAPI, ctx: ExtensionContext): Promise<LoadResult> {
	const config = await loadConfiguredSources(ctx.cwd, ctx.isProjectTrusted());
	const sources: ResolvedSource[] = [];
	const errors = [...config.errors];

	for (const source of config.sources) {
		try {
			const resolvedSource =
				source.kind === "path"
					? await ensureLocalDirectory(source)
					: await ensureRepository(pi, source, config.cacheDir!, config.autoUpdate ?? false);
			sources.push(resolvedSource);
		} catch (error) {
			errors.push(`@${source.alias}: ${(error as Error).message}`);
		}
	}

	return { sources, errors };
}

function sourceByAlias(alias: string): ResolvedSource | undefined {
	return activeSources.find((source) => source.alias === alias);
}

function resolveAliasPath(input: string): string | undefined {
	const normalized = normalizeSlashes(input.trim());
	if (!normalized.startsWith("@")) return undefined;

	const withoutAt = normalized.slice(1);
	const slashIndex = withoutAt.indexOf("/");
	const alias = slashIndex === -1 ? withoutAt : withoutAt.slice(0, slashIndex);
	const source = sourceByAlias(alias);
	if (!source) return undefined;

	const relativePath = slashIndex === -1 ? "" : withoutAt.slice(slashIndex + 1);
	return resolve(source.rootPath, relativePath);
}

function rewriteToolPathInputs(input: unknown): void {
	if (!isObject(input)) return;
	for (const field of ["path", "cwd"] as const) {
		const value = input[field];
		if (typeof value !== "string") continue;
		const resolved = resolveAliasPath(value);
		if (resolved) input[field] = resolved;
	}
}

function extractAgentSourceToken(textBeforeCursor: string): string | undefined {
	const match = textBeforeCursor.match(/(?:^|[\s])@([^\s]*)$/);
	return match?.[1];
}

async function scanEntries(rootPath: string, signal: AbortSignal): Promise<SourceEntry[]> {
	const entries: SourceEntry[] = [];

	async function walk(dir: string, prefix: string): Promise<void> {
		if (signal.aborted || entries.length >= MAX_SCAN_ENTRIES) return;

		let children;
		try {
			children = await readdir(dir, { withFileTypes: true });
		} catch {
			return;
		}

		children.sort((a, b) => a.name.localeCompare(b.name));
		for (const child of children) {
			if (signal.aborted || entries.length >= MAX_SCAN_ENTRIES) return;
			if (child.name === ".git") continue;

			const relativePath = prefix ? `${prefix}/${child.name}` : child.name;
			if (child.isDirectory()) {
				entries.push({ path: `${relativePath}/`, isDirectory: true });
				await walk(join(dir, child.name), relativePath);
			} else if (child.isFile() || child.isSymbolicLink()) {
				entries.push({ path: relativePath, isDirectory: false });
			}
		}
	}

	await walk(rootPath, "");
	return entries;
}

async function getSourceEntries(source: ResolvedSource, signal: AbortSignal): Promise<SourceEntry[]> {
	source.entriesPromise ??= scanEntries(source.rootPath, signal);
	return source.entriesPromise;
}

function formatEntryItem(source: ResolvedSource, entry: SourceEntry): AutocompleteItem {
	return {
		value: `@${source.alias}/${entry.path}`,
		label: `${basename(entry.path.replace(/\/$/, ""))}${entry.isDirectory ? "/" : ""}`,
		description: `@${source.alias}/${entry.path}`,
	};
}

function topLevelEntries(entries: SourceEntry[]): SourceEntry[] {
	return entries.filter((entry) => {
		const path = entry.path.replace(/\/$/, "");
		return !path.includes("/");
	});
}

async function sourcePathSuggestions(
	source: ResolvedSource,
	query: string,
	signal: AbortSignal,
): Promise<AutocompleteItem[]> {
	const entries = await getSourceEntries(source, signal);
	if (signal.aborted) return [];

	const normalizedQuery = normalizeSlashes(query).replace(/^\/+/, "");
	const matches = normalizedQuery
		? fuzzyFilter(entries, normalizedQuery, (entry) => entry.path).slice(0, MAX_SUGGESTIONS)
		: topLevelEntries(entries).slice(0, MAX_SUGGESTIONS);

	return matches.map((entry) => formatEntryItem(source, entry));
}

function sourceAliasSuggestions(token: string): AutocompleteItem[] {
	const visibleSources = activeSources.filter((source) => !source.hidden);
	const matches = token
		? fuzzyFilter(visibleSources, token, (source) => source.alias).slice(0, MAX_SUGGESTIONS)
		: visibleSources.slice(0, MAX_SUGGESTIONS);

	return matches.map((source) => ({
		value: `@${source.alias}/`,
		label: `@${source.alias}/`,
		description: source.description ?? source.rootPath,
	}));
}

function createAutocompleteProvider(current: AutocompleteProvider): AutocompleteProvider {
	return {
		triggerCharacters: ["@"],
		async getSuggestions(lines, cursorLine, cursorCol, options): Promise<AutocompleteSuggestions | null> {
			const line = lines[cursorLine] ?? "";
			const textBeforeCursor = line.slice(0, cursorCol);
			const token = extractAgentSourceToken(textBeforeCursor);
			if (token === undefined) {
				return current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			const slashIndex = token.indexOf("/");
			if (slashIndex === -1) {
				const items = sourceAliasSuggestions(token);
				if (items.length > 0) return { prefix: `@${token}`, items };
				return current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			const alias = token.slice(0, slashIndex);
			const source = sourceByAlias(alias);
			if (!source || source.hidden) {
				return current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			const query = token.slice(slashIndex + 1);
			const items = await sourcePathSuggestions(source, query, options.signal);
			if (items.length > 0) return { prefix: `@${token}`, items };
			return current.getSuggestions(lines, cursorLine, cursorCol, options);
		},
		applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
			return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
		},
		shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
			return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
		},
	};
}

function formatPromptSources(sources: ResolvedSource[]): string | undefined {
	const describedSources = sources.filter((source) => source.description?.trim());
	if (describedSources.length === 0) return undefined;

	const lines = [
		"## Agent Sources",
		"The pi-agent-sources extension provides external source aliases. Use them only when relevant to the user's task.",
		"File tools may receive @alias/relative/path; bash commands should use the resolved absolute path shown below.",
		"",
		...describedSources.map((source) => {
			const branch = source.branch ? `, ref: ${source.branch}` : "";
			return `- @${source.alias}: ${source.description} (path: ${source.rootPath}${branch})`;
		}),
	];

	return lines.join("\n");
}

function formatSourceReport(result: LoadResult): string {
	const lines = ["pi-agent-sources"];
	if (result.sources.length === 0) {
		lines.push("No sources configured.");
	} else {
		for (const source of result.sources) {
			const hidden = source.hidden ? " hidden" : "";
			const branch = source.branch ? ` ${source.branch}` : "";
			lines.push(`- @${source.alias} [${source.kind}${branch}${hidden}]: ${source.rootPath}`);
			if (source.description) lines.push(`  ${source.description}`);
		}
	}
	if (result.errors.length > 0) {
		lines.push("", "Errors:", ...result.errors.map((error) => `- ${error}`));
	}
	return lines.join("\n");
}

async function refresh(pi: ExtensionAPI, ctx: ExtensionContext): Promise<LoadResult> {
	const result = await resolveSources(pi, ctx);
	activeSources = result.sources;
	activeErrors = result.errors;

	if (ctx.hasUI) {
		ctx.ui.setStatus(
			CONFIG_KEY,
			activeSources.length > 0 ? `${activeSources.length} source${activeSources.length === 1 ? "" : "s"}` : undefined,
		);
		if (activeErrors.length > 0) {
			ctx.ui.notify(`${CONFIG_KEY}: ${activeErrors.length} configuration error(s). Run /agent-sources for details.`, "error");
		}
	}

	return result;
}

export default function piAgentSources(pi: ExtensionAPI): void {
	pi.on("session_start", async (_event, ctx) => {
		await refresh(pi, ctx);

		if (!autocompleteInstalled && ctx.hasUI) {
			autocompleteInstalled = true;
			ctx.ui.addAutocompleteProvider((current) => createAutocompleteProvider(current));
		}
	});

	pi.on("before_agent_start", async (event) => {
		const promptSources = formatPromptSources(activeSources);
		if (!promptSources) return;
		return { systemPrompt: `${event.systemPrompt}\n\n${promptSources}` };
	});

	pi.on("tool_call", async (event) => {
		rewriteToolPathInputs(event.input);
	});

	pi.registerCommand("agent-sources", {
		description: "List pi-agent-sources references from settings.json",
		argumentHint: "[reload]",
		getArgumentCompletions(prefix) {
			return "reload".startsWith(prefix.trim()) ? [{ value: "reload", label: "reload" }] : null;
		},
		handler: async (_args, ctx) => {
			const result = await refresh(pi, ctx);
			pi.sendMessage({
				customType: CONFIG_KEY,
				content: formatSourceReport(result),
				display: true,
				details: { sources: result.sources, errors: result.errors },
			});
		},
	});
}
