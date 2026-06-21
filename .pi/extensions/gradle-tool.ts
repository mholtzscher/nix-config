import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { Type } from "typebox";

const GRADLE_PARAMS = Type.Object({
	args: Type.Array(Type.String(), {
		description: "Arguments to pass to ./gradlew, for example [\":ktor-client-core:jvmTest\", \"--tests\", \"com.example.Test\"]. Do not include ./gradlew.",
	}),
});

function quoteArg(arg: string): string {
	if (/^[A-Za-z0-9_./:=@%+-]+$/.test(arg)) return arg;
	return `'${arg.replaceAll("'", `'\\''`)}'`;
}

function formatGradleCommand(args: string[]): string {
	const gradlew = process.platform === "win32" ? "gradlew.bat" : "./gradlew";
	return [gradlew, ...args.map(quoteArg)].join(" ");
}

function runGradle(cwd: string, args: string[], signal?: AbortSignal): Promise<{ exitCode: number | null; output: string }> {
	return new Promise((resolve) => {
		const gradlew = process.platform === "win32" ? "gradlew.bat" : "./gradlew";
		const command = process.platform === "win32" ? join(cwd, "gradlew.bat") : gradlew;
		const child = spawn(command, args, { cwd, shell: false });
		let output = "";

		const append = (chunk: Buffer) => {
			output += chunk.toString();
		};

		const abort = () => {
			child.kill("SIGTERM");
		};

		child.stdout.on("data", append);
		child.stderr.on("data", append);
		child.on("error", (error) => {
			resolve({ exitCode: 1, output: `${output}${error.message}\n` });
		});
		child.on("close", (exitCode) => {
			signal?.removeEventListener("abort", abort);
			resolve({ exitCode, output });
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
			text.setText(`${theme.fg("toolTitle", theme.bold("Gradle"))} ${theme.fg("dim", formatGradleCommand(params.args))}`);
			return text;
		},
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const command = formatGradleCommand(params.args);
			if (!existsSync(join(ctx.cwd, "gradlew")) && !existsSync(join(ctx.cwd, "gradlew.bat"))) {
				return {
					content: [{ type: "text", text: "gradlew not found in current working directory\n" }],
					details: { command },
					isError: true,
				};
			}

			const result = await runGradle(ctx.cwd, params.args, signal);
			if (result.exitCode === 0) {
				return {
					content: [{ type: "text", text: "Gradle succeeded." }],
					details: { command, exitCode: 0 },
				};
			}

			return {
				content: [{ type: "text", text: result.output }],
				details: { command, exitCode: result.exitCode },
				isError: true,
			};
		},
	});
}
