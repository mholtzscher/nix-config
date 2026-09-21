import { Plugin } from "@opencode/plugin"
import { CodexUsage, LiteLLMUsage, OpenCodeGoUsage } from "./rpc.js"
import type { QuotaProvider, QuotaWindow } from "./rpc.js"

const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"
const OPENCODE_GO_USAGE_URL = "https://opencode.ai/zen/go/v1/usage"
const WEEK_SECONDS = 7 * 24 * 60 * 60
const JWT_CLAIM_PATH = "https://api.openai.com/auth"

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

  const labels = { rolling: "Rolling", weekly: "Weekly", monthly: "Monthly" } as const
  const windows = Object.entries(labels).flatMap(([name, label]) => {
    const window = payload.usage[name]
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

const findBaseURL = (provider: unknown): string | undefined => {
  if (!isObject(provider)) return undefined
  for (const key of ["baseURL", "baseUrl", "apiBase", "api_base"]) {
    const value = provider[key]
    if (typeof value === "string" && value !== "") return value
  }
  for (const key of ["settings", "options", "info", "provider"]) {
    const value = findBaseURL(provider[key])
    if (value) return value
  }
}

const liteLLMManagementURL = (baseURL: string): URL => {
  const url = new URL(baseURL)
  url.pathname = url.pathname.replace(/\/?v1\/?$/, "/key/info")
  url.search = ""
  url.hash = ""
  return url
}

const parseLiteLLMUsage = (payload: unknown): QuotaWindow[] => {
  if (!isObject(payload)) throw new Error("key info missing")
  const info = isObject(payload.info) ? payload.info : payload
  const spend = numberValue(info.spend)
  const budget = numberValue(info.max_budget)
  if (spend === undefined || budget === undefined || budget <= 0) {
    throw new Error("budget missing")
  }
  const reset = typeof info.budget_reset_at === "string" ? Date.parse(info.budget_reset_at) : NaN
  return [{
    id: "budget",
    label: `$${spend.toFixed(2)} / $${budget.toFixed(2)}`,
    remainingPercent: remainingPercent((spend / budget) * 100),
    ...(Number.isFinite(reset) ? { resetAt: Math.floor(reset / 1000) } : {}),
  }]
}

const unavailable = (provider: QuotaProvider["provider"], name: string): QuotaProvider => ({
  provider,
  name,
  status: "unavailable",
  windows: [],
  message: "Usage unavailable",
  fetchedAt: Date.now(),
})

export default Plugin.define({
  id: "quota-usage",
  async setup(context) {
    await context.rpc.register(CodexUsage, {
      get: async (_input, rpcContext) => {
        try {
          const connection = await context.integration.connection.active("openai")
          if (!connection) return unavailable("codex", "Codex")
          const credential = await context.integration.connection.resolve(connection)
          const token = findAccessToken(credential)
          const accountID = token ? extractAccountID(token) : undefined
          if (!token || !accountID) return unavailable("codex", "Codex")

          const response = await fetch(CODEX_USAGE_URL, {
            headers: {
              authorization: `Bearer ${token}`,
              "chatgpt-account-id": accountID,
              originator: "opencode",
            },
            signal: AbortSignal.any([rpcContext.signal, AbortSignal.timeout(15_000)]),
          })
          if (!response.ok) throw new Error(`usage request failed: ${response.status}`)
          return {
            provider: "codex",
            name: "Codex",
            status: "ok",
            windows: parseCodexUsage(await response.json()),
            fetchedAt: Date.now(),
          } satisfies QuotaProvider
        } catch {
          return unavailable("codex", "Codex")
        }
      },
    })

    await context.rpc.register(OpenCodeGoUsage, {
      get: async (_input, rpcContext) => {
        try {
          const connection = await context.integration.connection.active("opencode-go")
          if (!connection) return unavailable("opencode-go", "OpenCode Go")
          const credential = await context.integration.connection.resolve(connection)
          const token = findAccessToken(credential)
          if (!token) return unavailable("opencode-go", "OpenCode Go")

          const response = await fetch(OPENCODE_GO_USAGE_URL, {
            headers: {
              accept: "application/json",
              authorization: `Bearer ${token}`,
            },
            signal: AbortSignal.any([rpcContext.signal, AbortSignal.timeout(15_000)]),
          })
          if (!response.ok) throw new Error(`usage request failed: ${response.status}`)
          return {
            provider: "opencode-go",
            name: "OpenCode Go",
            status: "ok",
            windows: parseOpenCodeGoUsage(await response.json()),
            fetchedAt: Date.now(),
          } satisfies QuotaProvider
        } catch {
          return unavailable("opencode-go", "OpenCode Go")
        }
      },
    })

    await context.rpc.register(LiteLLMUsage, {
      get: async (_input, rpcContext) => {
        try {
          const connection = await context.integration.connection.active("litellm")
          if (!connection) return unavailable("litellm", "LiteLLM")
          const credential = await context.integration.connection.resolve(connection)
          const token = findAccessToken(credential)
          const provider = await context.provider.get({ providerID: "litellm" })
          const baseURL = findBaseURL(provider)
          if (!token || !baseURL) return unavailable("litellm", "LiteLLM")

          const url = liteLLMManagementURL(baseURL)
          url.searchParams.set("key", token)
          const response = await fetch(url, {
            headers: {
              accept: "application/json",
              authorization: `Bearer ${token}`,
            },
            signal: AbortSignal.any([rpcContext.signal, AbortSignal.timeout(15_000)]),
          })
          if (!response.ok) throw new Error(`usage request failed: ${response.status}`)
          return {
            provider: "litellm",
            name: "LiteLLM",
            status: "ok",
            windows: parseLiteLLMUsage(await response.json()),
            fetchedAt: Date.now(),
          } satisfies QuotaProvider
        } catch {
          return unavailable("litellm", "LiteLLM")
        }
      },
    })
  },
})
