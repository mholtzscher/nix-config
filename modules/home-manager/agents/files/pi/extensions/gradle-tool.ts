import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { Type } from "typebox";

const DEFAULT_TIMEOUT_SECONDS = 300;

const GRADLE_PARAMS = Type.Object({
	args: Type.Array(Type.String(), {
		description: "Arguments to pass to ./gradlew, for example [\":ktor-client-core:jvmTest\", \"--tests\", \"com.example.Test\"]. Do not include ./gradlew.",
	}),
	timeoutSeconds: Type.Optional(
		Type.Integer({
			minimum: 1,
			default: DEFAULT_TIMEOUT_SECONDS,
			description: "Maximum seconds to wait before terminating Gradle. Defaults to 300.",
		}),
	),
	verbose: Type.Optional(
		Type.Boolean({
			default: false,
			description: "When false, run Gradle with -q. Defaults to false.",
		}),
	),
});

const DEFAULT_ARGS = ["--console=plain"];
const QUIET_ARGS = ["-q"];

function gradleWrapper(): string {
	return process.platform === "win32" ? "gradlew.bat" : "./gradlew";
}

function hasGradleWrapper(cwd: string): boolean {
	return existsSync(join(cwd, "gradlew")) || existsSync(join(cwd, "gradlew.bat"));
}

function effectiveGradleArgs(args: string[], verbose = false): string[] {
	return [...DEFAULT_ARGS, ...(verbose ? [] : QUIET_ARGS), ...args];
}

function formatGradleCommand(args: string[], verbose?: boolean): string {
	return [gradleWrapper(), ...effectiveGradleArgs(args, verbose)].join(" ");
}

function runGradle(cwd: string, args: string[], timeoutSeconds: number, signal?: AbortSignal): Promise<{ exitCode: number | null; output: string; timedOut: boolean }> {
	return new Promise((resolve) => {
		const child = spawn(gradleWrapper(), args, { cwd, shell: false });
		let output = "";
		let timedOut = false;
		let settled = false;

		const abort = () => {
			child.kill("SIGTERM");
		};

		const timeout = setTimeout(() => {
			timedOut = true;
			child.kill("SIGTERM");
		}, timeoutSeconds * 1000);

		const settle = (exitCode: number | null, text: string) => {
			if (settled) return;
			settled = true;
			clearTimeout(timeout);
			signal?.removeEventListener("abort", abort);
			resolve({ exitCode, output: text, timedOut });
		};

		const append = (chunk: Buffer) => {
			output += chunk.toString();
		};

		child.stdout.on("data", append);
		child.stderr.on("data", append);
		child.on("error", (error) => {
			settle(1, `${output}${error.message}\n`);
		});
		child.on("close", (exitCode) => {
			settle(exitCode, output);
		});

		if (signal?.aborted) {
			abort();
		} else {
			signal?.addEventListener("abort", abort, { once: true });
		}
	});
}

export default function gradleToolExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "gradle",
		label: "Gradle",
		description: "Run ./gradlew with the provided arguments. Returns a short success message on success and Gradle output only on failure.",
		promptSnippet: "Run ./gradlew with token-efficient output: short success, full output only on failure",
		promptGuidelines: [
			"Use gradle instead of bash for Gradle commands when token-efficient output is desired; pass only Gradle arguments, not ./gradlew.",
		],
		parameters: GRADLE_PARAMS,
		renderCall(params, theme, context) {
			const text = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
			const timeoutSeconds = params.timeoutSeconds ?? DEFAULT_TIMEOUT_SECONDS;
			text.setText(`${theme.fg("toolTitle", theme.bold("Gradle"))} ${theme.fg("dim", `(timeout=${timeoutSeconds}s) ${formatGradleCommand(params.args, params.verbose)}`)}`);
			return text;
		},
		renderResult(result, _options, theme, _context) {
			const details = result.details as { estimatedTokenSavings?: number; suppressedOutputChars?: number } | undefined;
			if (details?.estimatedTokenSavings !== undefined) {
				return new Text(
					`${theme.fg("success", "Gradle succeeded.")} ${theme.fg("dim", `Estimated savings: ~${details.estimatedTokenSavings.toLocaleString()} tokens (${(details.suppressedOutputChars ?? 0).toLocaleString()} chars suppressed).`)}`,
					0,
					0,
				);
			}

			const text = result.content[0];
			return new Text(text?.type === "text" ? text.text : "", 0, 0);
		},
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const args = effectiveGradleArgs(params.args, params.verbose);
			const command = formatGradleCommand(params.args, params.verbose);
			const timeoutSeconds = params.timeoutSeconds ?? DEFAULT_TIMEOUT_SECONDS;
			if (!hasGradleWrapper(ctx.cwd)) {
				return {
					content: [{ type: "text", text: "gradlew not found in current working directory\n" }],
					details: { command, timeoutSeconds },
					isError: true,
				};
			}

			const result = await runGradle(ctx.cwd, args, timeoutSeconds, signal);
			if (result.exitCode === 0) {
				const successText = "Gradle succeeded.";
				return {
					content: [{ type: "text", text: successText }],
					details: {
						command,
						exitCode: 0,
						estimatedTokenSavings: Math.max(0, Math.ceil(result.output.length / 4) - Math.ceil(successText.length / 4)),
						suppressedOutputChars: result.output.length,
					},
				};
			}

			return {
				content: [
					{
						type: "text",
						text: result.timedOut ? `${result.output}\nGradle timed out after ${timeoutSeconds} seconds.\n` : result.output,
					},
				],
				details: { command, exitCode: result.exitCode, timeoutSeconds, timedOut: result.timedOut },
				isError: true,
			};
		},
	});
}
