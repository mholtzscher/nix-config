import { Plugin } from "@opencode/plugin"
import { CodexUsage, OpenCodeGoUsage } from "./rpc.js"

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

const formatReset = (epochSeconds: number): string => {
  const minutes = Math.max(0, Math.floor((epochSeconds * 1000 - Date.now()) / 60_000))
  const days = Math.floor(minutes / 1440)
  const hours = Math.floor((minutes % 1440) / 60)
  if (days > 0) return `${days}d${hours > 0 ? `${hours}h` : ""}`
  if (hours > 0) return `${hours}h`
  return `${minutes}m`
}

const formatUsage = (payload: unknown): string => {
  if (!isObject(payload) || !isObject(payload.rate_limit)) throw new Error("rate limit missing")
  const rateLimit = payload.rate_limit
  const windows = [rateLimit.primary_window, rateLimit.secondary_window].filter(isObject)
  const weekly = windows.find((window) => numberValue(window.limit_window_seconds) === WEEK_SECONDS)
    ?? windows.at(-1)
  if (!weekly) throw new Error("weekly window missing")

  const used = numberValue(weekly.used_percent)
  if (used === undefined) throw new Error("weekly usage missing")
  const remaining = Math.max(0, Math.min(100, 100 - used))
  const resetAt = numberValue(weekly.reset_at)
  return `CX ${remaining.toFixed(0)}%${resetAt === undefined ? "" : ` [${formatReset(resetAt)}]`}`
}

const formatOpenCodeGoUsage = (payload: unknown): string => {
  if (!isObject(payload) || !isObject(payload.usage)) throw new Error("usage windows missing")

  const labels = { rolling: "R", weekly: "W", monthly: "M" } as const
  const formatted = Object.entries(labels).flatMap(([name, label]) => {
    const window = payload.usage[name]
    if (!isObject(window)) return []
    const used = numberValue(window.percent)
    if (used === undefined || typeof window.resetsAt !== "string") return []
    const remaining = Math.max(0, Math.min(100, 100 - used))
    return [`${label}${remaining.toFixed(0)}%`]
  })
  if (formatted.length === 0) throw new Error("usage windows missing")
  return `GO ${formatted.join(" ")}`
}

export default Plugin.define({
  id: "quota-usage",
  async setup(context) {
    await context.rpc.register(CodexUsage, {
      get: async (_input, rpcContext) => {
        try {
          const connection = await context.integration.connection.active("openai")
          if (!connection) return { text: "CX unavailable" }
          const credential = await context.integration.connection.resolve(connection)
          const token = findAccessToken(credential)
          const accountID = token ? extractAccountID(token) : undefined
          if (!token || !accountID) return { text: "CX unavailable" }

          const response = await fetch(CODEX_USAGE_URL, {
            headers: {
              authorization: `Bearer ${token}`,
              "chatgpt-account-id": accountID,
              originator: "opencode",
            },
            signal: AbortSignal.any([rpcContext.signal, AbortSignal.timeout(15_000)]),
          })
          if (!response.ok) throw new Error(`usage request failed: ${response.status}`)
          return { text: formatUsage(await response.json()) }
        } catch {
          return { text: "CX unavailable" }
        }
      },
    })

    await context.rpc.register(OpenCodeGoUsage, {
      get: async (_input, rpcContext) => {
        try {
          const connection = await context.integration.connection.active("opencode-go")
          if (!connection) return { text: "GO unavailable" }
          const credential = await context.integration.connection.resolve(connection)
          const token = findAccessToken(credential)
          if (!token) return { text: "GO unavailable" }

          const response = await fetch(OPENCODE_GO_USAGE_URL, {
            headers: {
              accept: "application/json",
              authorization: `Bearer ${token}`,
            },
            signal: AbortSignal.any([rpcContext.signal, AbortSignal.timeout(15_000)]),
          })
          if (!response.ok) throw new Error(`usage request failed: ${response.status}`)
          return { text: formatOpenCodeGoUsage(await response.json()) }
        } catch {
          return { text: "GO unavailable" }
        }
      },
    })
  },
})
