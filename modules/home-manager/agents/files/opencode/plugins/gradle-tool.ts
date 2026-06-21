import { type Plugin, tool } from "@opencode-ai/plugin"
import { spawn } from "node:child_process"
import { existsSync } from "node:fs"
import { join } from "node:path"

type GradleResult = {
  exitCode: number | null
  output: string
}

function quoteArg(arg: string): string {
  if (/^[A-Za-z0-9_./:=@%+-]+$/.test(arg)) return arg
  return `'${arg.replaceAll("'", `'\\''`)}'`
}

function formatGradleCommand(args: string[]): string {
  const gradlew = process.platform === "win32" ? "gradlew.bat" : "./gradlew"
  return [gradlew, ...args.map(quoteArg)].join(" ")
}

function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4)
}

function estimateTokenSavings(fullOutput: string, returnedText: string): number {
  return Math.max(0, estimateTokens(fullOutput) - estimateTokens(returnedText))
}

function runGradle(cwd: string, args: string[]): Promise<GradleResult> {
  return new Promise((resolve) => {
    const command = process.platform === "win32" ? join(cwd, "gradlew.bat") : "./gradlew"
    const child = spawn(command, args, { cwd, shell: false })
    let output = ""

    const append = (chunk: Buffer) => {
      output += chunk.toString()
    }

    child.stdout.on("data", append)
    child.stderr.on("data", append)
    child.on("error", (error) => {
      resolve({ exitCode: 1, output: `${output}${error.message}\n` })
    })
    child.on("close", (exitCode) => {
      resolve({ exitCode, output })
    })
  })
}

export const GradleToolPlugin: Plugin = async () => {
  return {
    tool: {
      gradle: tool({
        description:
          "Run ./gradlew with the provided arguments. Returns a short success message on success and Gradle output only on failure. Pass only Gradle arguments, not ./gradlew.",
        args: {
          args: tool.schema
            .array(tool.schema.string())
            .describe(
              'Arguments to pass to ./gradlew, for example [":ktor-client-core:jvmTest", "--tests", "com.example.Test"]. Do not include ./gradlew.',
            ),
        },
        async execute(args, context) {
          const cwd = context.directory
          const command = formatGradleCommand(args.args)

          if (!existsSync(join(cwd, "gradlew")) && !existsSync(join(cwd, "gradlew.bat"))) {
            return `gradlew not found in current working directory\nCommand: ${command}`
          }

          const result = await runGradle(cwd, args.args)
          if (result.exitCode === 0) {
            const successText = "Gradle succeeded."
            const estimatedTokenSavings = estimateTokenSavings(result.output, successText)
            return `${successText} Estimated savings: ~${estimatedTokenSavings.toLocaleString()} tokens (${result.output.length.toLocaleString()} chars suppressed).`
          }

          return result.output
        },
      }),
    },
  }
}
