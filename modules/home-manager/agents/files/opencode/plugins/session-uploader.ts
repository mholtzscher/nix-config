import type { Plugin } from "@opencode-ai/plugin"

type UploadConfig = {
  url?: string
  token?: string
  authHeader: string
  authScheme: string
  command: string
  events: Set<string>
  debounceMs: number
  timeoutMs: number
  includeMessages: boolean
  includeProject: boolean
  includeEnvironment: boolean
}

type UploadResult =
  | { ok: true; status: number; responseText: string; responseJson?: unknown }
  | { ok: false; status?: number; statusText?: string; responseText?: string; error?: string }

function parseBool(value: string | undefined, fallback: boolean): boolean {
  if (value == null || value === "") return fallback
  return ["1", "true", "yes", "on"].includes(value.toLowerCase())
}

function parseIntEnv(value: string | undefined, fallback: number): number {
  if (value == null || value === "") return fallback
  const parsed = Number.parseInt(value, 10)
  return Number.isFinite(parsed) ? parsed : fallback
}

function loadConfig(): UploadConfig {
  // Empty by default: uploads happen on /share-session. Set this env var to opt
  // back into automatic event uploads, eg: session.idle,message.updated
  const events = (process.env.OPENCODE_SESSION_UPLOAD_EVENTS ?? "")
    .split(",")
    .map((event) => event.trim())
    .filter(Boolean)

  return {
    url: process.env.OPENCODE_SESSION_UPLOAD_URL,
    token: process.env.OPENCODE_SESSION_UPLOAD_TOKEN,
    authHeader: process.env.OPENCODE_SESSION_UPLOAD_AUTH_HEADER || "Authorization",
    authScheme: process.env.OPENCODE_SESSION_UPLOAD_AUTH_SCHEME ?? "Bearer",
    command: process.env.OPENCODE_SESSION_UPLOAD_COMMAND || "share-session",
    events: new Set(events),
    debounceMs: parseIntEnv(process.env.OPENCODE_SESSION_UPLOAD_DEBOUNCE_MS, 1500),
    timeoutMs: parseIntEnv(process.env.OPENCODE_SESSION_UPLOAD_TIMEOUT_MS, 10000),
    includeMessages: parseBool(process.env.OPENCODE_SESSION_UPLOAD_INCLUDE_MESSAGES, true),
    includeProject: parseBool(process.env.OPENCODE_SESSION_UPLOAD_INCLUDE_PROJECT, true),
    includeEnvironment: parseBool(process.env.OPENCODE_SESSION_UPLOAD_INCLUDE_ENVIRONMENT, false),
  }
}

function getSessionID(event: unknown): string | undefined {
  const candidate = event as {
    properties?: {
      sessionID?: string
      sessionId?: string
      session?: { id?: string }
      info?: { id?: string; sessionID?: string; sessionId?: string }
    }
  }

  return (
    candidate.properties?.sessionID ||
    candidate.properties?.sessionId ||
    candidate.properties?.session?.id ||
    candidate.properties?.info?.sessionID ||
    candidate.properties?.info?.sessionId ||
    candidate.properties?.info?.id
  )
}

function redactEnv(env: Record<string, string | undefined>): Record<string, string> {
  const redacted: Record<string, string> = {}
  for (const [key, value] of Object.entries(env)) {
    if (value == null) continue
    if (/TOKEN|SECRET|PASSWORD|KEY|AUTH|CREDENTIAL/i.test(key)) {
      redacted[key] = "[redacted]"
    } else {
      redacted[key] = value
    }
  }
  return redacted
}

function formatUploadResult(result: UploadResult): string {
  if (!result.ok) {
    const detail = result.error || result.responseText || result.statusText || "unknown error"
    return `Session upload failed${result.status ? ` (${result.status})` : ""}: ${detail}`
  }

  if (result.responseJson && typeof result.responseJson === "object" && "path" in result.responseJson) {
    return `Session uploaded: ${(result.responseJson as { path: unknown }).path}`
  }

  return `Session uploaded (${result.status})`
}

export const SessionUploader: Plugin = async (ctx) => {
  const config = loadConfig()
  const pending = new Map<string, ReturnType<typeof setTimeout>>()

  async function log(level: "debug" | "info" | "warn" | "error", message: string, extra?: Record<string, unknown>) {
    try {
      await ctx.client.app.log({
        body: {
          service: "session-uploader",
          level,
          message,
          extra,
        },
      })
    } catch {
      // Logging must never break opencode.
    }
  }

  async function showToast(message: string, variant: "success" | "error" = "success") {
    try {
      await ctx.client.tui.showToast({ body: { message, variant } })
    } catch {
      // Toasts are best effort.
    }
  }

  async function upload(sessionID: string, trigger: string, extra?: Record<string, unknown>): Promise<UploadResult> {
    if (!config.url) {
      return { ok: false, error: "OPENCODE_SESSION_UPLOAD_URL is not set" }
    }

    const abort = new AbortController()
    const timeout = setTimeout(() => abort.abort(), config.timeoutMs)

    try {
      const [session, messages] = await Promise.all([
        ctx.client.session.get({ path: { id: sessionID } }),
        config.includeMessages
          ? ctx.client.session.messages({ path: { id: sessionID } })
          : Promise.resolve(undefined),
      ])

      const headers: Record<string, string> = {
        "content-type": "application/json",
        "user-agent": "opencode-session-uploader",
      }

      if (config.token) {
        headers[config.authHeader] = config.authScheme
          ? `${config.authScheme} ${config.token}`
          : config.token
      }

      const response = await fetch(config.url, {
        method: "POST",
        headers,
        signal: abort.signal,
        body: JSON.stringify({
          version: 1,
          trigger,
          uploadedAt: new Date().toISOString(),
          session,
          messages,
          project: config.includeProject
            ? {
                directory: ctx.directory,
                worktree: ctx.worktree,
                project: ctx.project,
              }
            : undefined,
          environment: config.includeEnvironment ? redactEnv(process.env) : undefined,
          extra,
        }),
      })

      const responseText = await response.text().catch(() => "")
      let responseJson: unknown
      try {
        responseJson = responseText ? JSON.parse(responseText) : undefined
      } catch {
        responseJson = undefined
      }

      if (!response.ok) {
        const result: UploadResult = {
          ok: false,
          status: response.status,
          statusText: response.statusText,
          responseText,
        }
        await log("warn", "Session upload failed", { sessionID, trigger, ...result })
        return result
      }

      const result: UploadResult = { ok: true, status: response.status, responseText, responseJson }
      await log("debug", "Session uploaded", { sessionID, trigger, status: response.status })
      return result
    } catch (error) {
      const result: UploadResult = {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      }
      await log("error", "Session upload errored", { sessionID, trigger, ...result })
      return result
    } finally {
      clearTimeout(timeout)
    }
  }

  function schedule(sessionID: string, trigger: string) {
    const existing = pending.get(sessionID)
    if (existing) clearTimeout(existing)

    pending.set(
      sessionID,
      setTimeout(() => {
        pending.delete(sessionID)
        void upload(sessionID, trigger)
      }, config.debounceMs),
    )
  }

  if (!config.url) {
    await log("info", "Session uploader loaded but disabled; set OPENCODE_SESSION_UPLOAD_URL")
  } else {
    await log("info", "Session uploader enabled", {
      url: config.url,
      command: config.command,
      automaticEvents: [...config.events],
      includeMessages: config.includeMessages,
    })
  }

  return {
    "command.execute.before": async (input) => {
      if (input.command !== config.command) return

      const result = await upload(input.sessionID, `command.${config.command}`, {
        command: input.command,
        arguments: input.arguments,
      })
      const message = formatUploadResult(result)
      await showToast(message, result.ok ? "success" : "error")

      // This command is handled completely by the plugin. The current opencode
      // command hook convention is to throw "skip" to avoid an LLM round trip.
      throw new Error("skip")
    },

    event: async ({ event }) => {
      if (!config.url || !config.events.has(event.type)) return

      const sessionID = getSessionID(event)
      if (!sessionID) {
        await log("debug", "Skipped upload event without session id", { eventType: event.type })
        return
      }

      schedule(sessionID, event.type)
    },
  }
}
