import { Plugin } from "@opencode/plugin/effect"
import { Effect } from "effect"
import { CodexUsage, OpenCodeGoUsage } from "./rpc.js"
import type { QuotaProvider, QuotaWindow } from "./rpc.js"

const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"
const OPENCODE_GO_USAGE_URL = "https://opencode.ai/zen/go/v1/usage"
const WEEK_SECONDS = 7 * 24 * 60 * 60
const JWT_CLAIM_PATH = "https://api.openai.com/auth"
const USAGE_TIMEOUT = "15 seconds"

type JsonObject = { [key: string]: unknown }

const isObject = (value: unknown): value is JsonObject =>
  typeof value === "object" && value !== null

const numberValue = (value: unknown): number | undefined => {
  if (typeof value === "number" && Number.isFinite(value)) return value
  if (typeof value === "string" && value.trim() !== "" && Number.isFinite(Number(value))) {
    return Number(value)
  }
}

const findAccessToken = (credential: unknown): string | undefined => {
  if (typeof credential === "string") return credential
  if (!isObject(credential)) return undefined

  for (const key of ["access", "accessToken", "access_token", "token", "key"]) {
    const value = credential[key]
    if (typeof value === "string" && value !== "") return value
  }

  for (const value of Object.values(credential)) {
    const token = findAccessToken(value)
    if (token?.split(".").length === 3) return token
  }
}

const extractAccountID = (token: string): string | undefined => {
  try {
    const parts = token.split(".")
    if (parts.length !== 3 || !parts[1]) return undefined
    const payload: unknown = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"))
    if (!isObject(payload)) return undefined
    const auth = payload[JWT_CLAIM_PATH]
    if (!isObject(auth)) return undefined
    const accountID = auth.chatgpt_account_id
    return typeof accountID === "string" && accountID !== "" ? accountID : undefined
  } catch {
    return undefined
  }
}

const remainingPercent = (used: number): number => Math.max(0, Math.min(100, 100 - used))

const parseCodexUsage = (payload: unknown): QuotaWindow[] => {
  if (!isObject(payload) || !isObject(payload.rate_limit)) throw new Error("rate limit missing")
  const rateLimit = payload.rate_limit
  const windows = [rateLimit.primary_window, rateLimit.secondary_window].filter(isObject)
  const weekly = windows.find((window) => numberValue(window.limit_window_seconds) === WEEK_SECONDS)
    ?? windows.at(-1)
  if (!weekly) throw new Error("weekly window missing")

  const used = numberValue(weekly.used_percent)
  if (used === undefined) throw new Error("weekly usage missing")
  const resetAt = numberValue(weekly.reset_at)
  return [{
    id: "weekly",
    label: "Weekly",
    remainingPercent: remainingPercent(used),
    ...(resetAt === undefined ? {} : { resetAt }),
  }]
}

const parseOpenCodeGoUsage = (payload: unknown): QuotaWindow[] => {
  if (!isObject(payload) || !isObject(payload.usage)) throw new Error("usage windows missing")
  const usage = payload.usage

  const labels = { rolling: "Rolling", weekly: "Weekly", monthly: "Monthly" } as const
  const windows = Object.entries(labels).flatMap(([name, label]) => {
    const window = usage[name]
    if (!isObject(window)) return []
    const used = numberValue(window.percent)
    if (used === undefined || typeof window.resetsAt !== "string") return []
    const parsedReset = Date.parse(window.resetsAt)
    return [{
      id: name,
      label,
      remainingPercent: remainingPercent(used),
      ...(Number.isFinite(parsedReset) ? { resetAt: Math.floor(parsedReset / 1000) } : {}),
    }]
  })
  if (windows.length === 0) throw new Error("usage windows missing")
  return windows
}

const unavailable = (provider: QuotaProvider["provider"], name: string): QuotaProvider => ({
  provider,
  name,
  status: "unavailable",
  windows: [],
  message: "Usage unavailable",
  fetchedAt: Date.now(),
})

const fetchUsage = (
  input: string | URL,
  init: RequestInit,
): Effect.Effect<unknown, unknown> =>
  Effect.tryPromise({
    try: async (signal) => {
      const response = await fetch(input, { ...init, signal })
      if (!response.ok) throw new Error(`usage request failed: ${response.status}`)
      return (await response.json()) as unknown
    },
    catch: (cause) => cause,
  }).pipe(Effect.timeout(USAGE_TIMEOUT))

const quotaHandler = (
  provider: QuotaProvider["provider"],
  name: string,
  body: Effect.Effect<QuotaProvider, unknown>,
): Effect.Effect<QuotaProvider> =>
  body.pipe(
    Effect.catchDefect(() => Effect.succeed(unavailable(provider, name))),
    Effect.orElseSucceed(() => unavailable(provider, name)),
  )

const codexQuota = (context: Plugin.Context): Effect.Effect<QuotaProvider, unknown> =>
  Effect.gen(function* () {
    const connection = yield* context.integration.connection.active("openai")
    if (!connection) return unavailable("codex", "Codex")
    const credential = yield* context.integration.connection.resolve(connection)
    const token = findAccessToken(credential)
    const accountID = token ? extractAccountID(token) : undefined
    if (!token || !accountID) return unavailable("codex", "Codex")

    const payload = yield* fetchUsage(CODEX_USAGE_URL, {
      headers: {
        authorization: `Bearer ${token}`,
        "chatgpt-account-id": accountID,
        originator: "opencode",
      },
    })
    return {
      provider: "codex",
      name: "Codex",
      status: "ok",
      windows: parseCodexUsage(payload),
      fetchedAt: Date.now(),
    } satisfies QuotaProvider
  })

const openCodeGoQuota = (context: Plugin.Context): Effect.Effect<QuotaProvider, unknown> =>
  Effect.gen(function* () {
    const connection = yield* context.integration.connection.active("opencode-go")
    if (!connection) return unavailable("opencode-go", "OpenCode Go")
    const credential = yield* context.integration.connection.resolve(connection)
    const token = findAccessToken(credential)
    if (!token) return unavailable("opencode-go", "OpenCode Go")

    const payload = yield* fetchUsage(OPENCODE_GO_USAGE_URL, {
      headers: {
        accept: "application/json",
        authorization: `Bearer ${token}`,
      },
    })
    return {
      provider: "opencode-go",
      name: "OpenCode Go",
      status: "ok",
      windows: parseOpenCodeGoUsage(payload),
      fetchedAt: Date.now(),
    } satisfies QuotaProvider
  })

export default Plugin.define({
  id: "quota-usage",
  effect: (context) =>
    Effect.gen(function* () {
      yield* context.rpc
        .register(CodexUsage, { get: () => quotaHandler("codex", "Codex", codexQuota(context)) })
        .pipe(Effect.orDie)
      yield* context.rpc
        .register(OpenCodeGoUsage, {
          get: () => quotaHandler("opencode-go", "OpenCode Go", openCodeGoQuota(context)),
        })
        .pipe(Effect.orDie)
    }),
})
