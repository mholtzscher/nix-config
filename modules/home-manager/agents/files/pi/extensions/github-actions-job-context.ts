import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const GITHUB_ACTIONS_JOB_URL = /https?:\/\/github\.com\/([^\s\/]+)\/([^\s\/]+)\/actions\/runs\/(\d+)\/job\/(\d+)(?:[^\s<>)\]]*)?/gi;
const MAX_FAILED_LOG_CHARS = 22_000;
const MAX_CONTEXT_CHARS = 30_000;
const MAX_URLS_PER_PROMPT = 3;
const ERROR_LINE_PATTERN = /(^|[\s›])(✘|error|failed|failure|exception|traceback|panic|fatal|GH\d{3}|exit code|remote:|rejected|denied|timed out|segmentation fault|core dumped)/i;

type GithubJobUrl = {
	url: string;
	owner: string;
	repo: string;
	runId: string;
	jobId: string;
};

type GhResult = {
	stdout: string;
	stderr: string;
};

function runGh(args: string[], signal?: AbortSignal): Promise<GhResult> {
	return new Promise((resolve, reject) => {
		const child = execFile(
			"gh",
			args,
			{
				timeout: 60_000,
				maxBuffer: 12 * 1024 * 1024,
				encoding: "utf8",
				env: { ...process.env, GH_PAGER: "cat", PAGER: "cat" },
			},
			(error, stdout, stderr) => {
				if (error) {
					const message = [
						`gh ${args.join(" ")} failed: ${error.message}`,
						stderr?.trim(),
					]
						.filter(Boolean)
						.join("\n");
					reject(new Error(message));
					return;
				}
				resolve({ stdout, stderr });
			},
		);

		if (signal) {
			if (signal.aborted) child.kill();
			signal.addEventListener("abort", () => child.kill(), { once: true });
		}
	});
}

function uniqueJobUrls(text: string): GithubJobUrl[] {
	const seen = new Set<string>();
	const urls: GithubJobUrl[] = [];
	for (const match of text.matchAll(GITHUB_ACTIONS_JOB_URL)) {
		const [url, owner, repo, runId, jobId] = match;
		const key = `${owner}/${repo}/${jobId}`;
		if (seen.has(key)) continue;
		seen.add(key);
		urls.push({ url, owner, repo, runId, jobId });
		if (urls.length >= MAX_URLS_PER_PROMPT) break;
	}
	return urls;
}

function truncate(text: string, maxChars: number): string {
	if (text.length <= maxChars) return text;
	return `${text.slice(0, maxChars)}\n\n[truncated ${text.length - maxChars} characters]`;
}

function stripAnsi(text: string): string {
	return text
		.replace(/\u001b\[[0-9;?]*[ -/]*[@-~]/g, "")
		.replace(/\uFEFF/g, "");
}

function normalizeLogLine(line: string): string {
	const cleaned = stripAnsi(line);
	const parts = cleaned.split("\t");
	if (parts.length >= 3) return `${parts[1]} | ${parts.slice(2).join("\t")}`;
	return cleaned;
}

function logMessageForMatching(line: string): string {
	const separator = line.indexOf(" | ");
	return separator === -1 ? line : line.slice(separator + 3);
}

function lineWindow(lines: string[], index: number, before = 8, after = 14): [number, number] {
	return [Math.max(0, index - before), Math.min(lines.length, index + after + 1)];
}

function mergeWindows(windows: Array<[number, number]>): Array<[number, number]> {
	const sorted = [...windows].sort((a, b) => a[0] - b[0]);
	const merged: Array<[number, number]> = [];
	for (const window of sorted) {
		const previous = merged[merged.length - 1];
		if (!previous || window[0] > previous[1] + 2) {
			merged.push([...window] as [number, number]);
		} else {
			previous[1] = Math.max(previous[1], window[1]);
		}
	}
	return merged;
}

function summarizeFailedLog(rawLog: string): string {
	const normalized = stripAnsi(rawLog)
		.split(/\r?\n/)
		.map(normalizeLogLine)
		.filter((line) => line.trim().length > 0);

	if (normalized.length === 0) return "No failed-step logs returned by gh.";

	const errorWindows = mergeWindows(
		normalized
			.map((line, index) => ERROR_LINE_PATTERN.test(logMessageForMatching(line)) ? lineWindow(normalized, index) : undefined)
			.filter((window): window is [number, number] => Boolean(window)),
	);

	const sections: string[] = [
		`Full failed-step log lines: ${normalized.length}`,
	];

	if (errorWindows.length > 0) {
		sections.push("### Error-focused excerpts");
		const selectedWindows = mergeWindows([
			...errorWindows.slice(0, 3),
			...errorWindows.slice(-3),
		]);
		for (const [start, end] of selectedWindows) {
			sections.push(`--- lines ${start + 1}-${end} ---\n${normalized.slice(start, end).join("\n")}`);
		}
	} else {
		sections.push("No obvious error markers found; including tail of failed-step log.");
	}

	const tailLineCount = errorWindows.length > 0 ? 120 : 180;
	const tailStart = Math.max(0, normalized.length - tailLineCount);
	sections.push(`### Tail (${normalized.length - tailStart} lines)\n${normalized.slice(tailStart).join("\n")}`);

	return truncate(sections.join("\n\n"), MAX_FAILED_LOG_CHARS);
}

async function saveFullLog(jobUrl: GithubJobUrl, log: string): Promise<string> {
	const dir = join(tmpdir(), "pi-github-actions-logs");
	await mkdir(dir, { recursive: true });
	const safeRepo = `${jobUrl.owner}-${jobUrl.repo}`.replace(/[^a-z0-9_.-]/gi, "-");
	const file = join(dir, `${safeRepo}-${jobUrl.runId}-${jobUrl.jobId}.log`);
	await writeFile(file, stripAnsi(log));
	return file;
}

function parseJson<T>(text: string): T | undefined {
	try {
		return JSON.parse(text) as T;
	} catch {
		return undefined;
	}
}

function formatJson(value: unknown): string {
	return JSON.stringify(value, null, 2);
}

function failedOrInterestingSteps(job: any): any[] {
	const steps = Array.isArray(job?.steps) ? job.steps : [];
	return steps.filter((step) => {
		const conclusion = String(step?.conclusion ?? "").toLowerCase();
		const status = String(step?.status ?? "").toLowerCase();
		return ["failure", "cancelled", "timed_out", "action_required"].includes(conclusion) || status !== "completed";
	});
}

function checkRunIdFromJob(job: any): string | undefined {
	const url = typeof job?.check_run_url === "string" ? job.check_run_url : "";
	return url.match(/\/check-runs\/(\d+)$/)?.[1];
}

async function collectContext(jobUrl: GithubJobUrl, signal?: AbortSignal): Promise<string> {
	const repoArg = `${jobUrl.owner}/${jobUrl.repo}`;
	const sections: string[] = [];

	sections.push(`## GitHub Actions job URL\n${jobUrl.url}`);
	sections.push(`Repository: ${repoArg}\nRun ID: ${jobUrl.runId}\nJob ID: ${jobUrl.jobId}`);

	try {
		const jobResult = await runGh([
			"api",
			`repos/${repoArg}/actions/jobs/${jobUrl.jobId}`,
		], signal);
		const job = parseJson<any>(jobResult.stdout);
		if (job) {
			sections.push(`## Job summary\n${formatJson({
				name: job.name,
				status: job.status,
				conclusion: job.conclusion,
				started_at: job.started_at,
				completed_at: job.completed_at,
				runner_name: job.runner_name,
				runner_group_name: job.runner_group_name,
				labels: job.labels,
				head_sha: job.head_sha,
				run_attempt: job.run_attempt,
				workflow_name: job.workflow_name,
				html_url: job.html_url,
				check_run_url: job.check_run_url,
			})}`);

			const interestingSteps = failedOrInterestingSteps(job);
			sections.push(`## Failed or incomplete steps\n${interestingSteps.length > 0 ? formatJson(interestingSteps) : "None reported by the jobs API."}`);

			const checkRunId = checkRunIdFromJob(job);
			if (checkRunId) {
				try {
					const annotationsResult = await runGh([
						"api",
						`repos/${repoArg}/check-runs/${checkRunId}/annotations`,
						"--paginate",
					], signal);
					const annotations = parseJson<any[]>(annotationsResult.stdout);
					if (annotations?.length) {
						sections.push(`## Check annotations\n${formatJson(annotations.map((annotation) => ({
							path: annotation.path,
							start_line: annotation.start_line,
							end_line: annotation.end_line,
							annotation_level: annotation.annotation_level,
							message: annotation.message,
							title: annotation.title,
							raw_details: annotation.raw_details,
						})))}`);
					}
				} catch (error) {
					sections.push(`## Check annotations lookup failed\n${error instanceof Error ? error.message : String(error)}`);
				}
			}
		}
	} catch (error) {
		sections.push(`## Job API lookup failed\n${error instanceof Error ? error.message : String(error)}`);
	}

	try {
		const runResult = await runGh([
			"run",
			"view",
			jobUrl.runId,
			"--repo",
			repoArg,
			"--json",
			"attempt,conclusion,createdAt,databaseId,displayTitle,event,headBranch,headSha,jobs,name,number,startedAt,status,updatedAt,url,workflowDatabaseId,workflowName",
		], signal);
		const run = parseJson<any>(runResult.stdout);
		if (run) {
			sections.push(`## Workflow run summary\n${formatJson({
				name: run.name,
				workflowName: run.workflowName,
				displayTitle: run.displayTitle,
				status: run.status,
				conclusion: run.conclusion,
				event: run.event,
				headBranch: run.headBranch,
				headSha: run.headSha,
				attempt: run.attempt,
				startedAt: run.startedAt,
				updatedAt: run.updatedAt,
				url: run.url,
			})}`);
		}
	} catch (error) {
		sections.push(`## Run summary lookup failed\n${error instanceof Error ? error.message : String(error)}`);
	}

	try {
		const logResult = await runGh([
			"run",
			"view",
			jobUrl.runId,
			"--repo",
			repoArg,
			"--job",
			jobUrl.jobId,
			"--log-failed",
		], signal);
		const fullLogPath = await saveFullLog(jobUrl, logResult.stdout);
		sections.push(`## Failed step logs\nFull failed-step log saved at: ${fullLogPath}\n\n${summarizeFailedLog(logResult.stdout)}`);
	} catch (error) {
		sections.push(`## Failed-step log lookup failed\n${error instanceof Error ? error.message : String(error)}`);
	}

	return truncate(sections.join("\n\n"), MAX_CONTEXT_CHARS);
}

export default function (pi: ExtensionAPI) {
	pi.on("input", async (event, ctx) => {
		if (event.source === "extension") return { action: "continue" };

		const jobUrls = uniqueJobUrls(event.text);
		if (jobUrls.length === 0) return { action: "continue" };

		ctx.ui.notify(`Fetching GitHub Actions context for ${jobUrls.length} job URL${jobUrls.length === 1 ? "" : "s"}...`, "info");

		const contexts = await Promise.all(jobUrls.map(async (jobUrl) => {
			try {
				return await collectContext(jobUrl, ctx.signal);
			} catch (error) {
				return `## GitHub Actions job context lookup failed\nURL: ${jobUrl.url}\n${error instanceof Error ? error.message : String(error)}`;
			}
		}));

		const injectedContext = contexts.join("\n\n---\n\n");
		return {
			action: "transform",
			text: `${event.text}\n\n<github-actions-job-context>\n${injectedContext}\n</github-actions-job-context>`,
			images: event.images,
		};
	});
}
