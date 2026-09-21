import { Plugin, Provider } from "@opencode/plugin/effect"
import { Effect } from "effect"
import { CodexUsage, LiteLLMUsage, OpenCodeGoUsage } from "./rpc.js"
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

const findBaseURL = (provider: unknown): string | undefined => {
  if (!isObject(provider)) return undefined
  for (const key of ["baseURL", "baseUrl", "apiBase", "api_base"]) {
    const value = provider[key]
    if (typeof value === "string" && value !== "") return value
  }
  for (const key of ["settings", "options", "info", "provider", "data"]) {
    const value = findBaseURL(provider[key])
    if (value) return value
  }
}

const findApiKey = (provider: unknown): string | undefined => {
  if (!isObject(provider)) return undefined
  for (const key of ["apiKey", "api_key", "key", "token"]) {
    const value = provider[key]
    if (typeof value === "string" && value !== "") return value
  }
  for (const key of ["settings", "options", "info", "provider", "data"]) {
    const value = findApiKey(provider[key])
    if (value) return value
  }
}

const liteLLMManagementURL = (baseURL: string): URL => {
  const url = new URL(baseURL)
  url.pathname = url.pathname.replace(/\/?v1\/?$/, "/user/info")
  url.search = ""
  url.hash = ""
  return url
}

const parseLiteLLMBudget = (
  info: JsonObject,
  id: string,
  label: string,
): QuotaWindow | undefined => {
  const spend = numberValue(info.spend)
  const budget = numberValue(info.max_budget)
  if (spend === undefined || budget === undefined || budget <= 0) return undefined
  const reset = typeof info.budget_reset_at === "string" ? Date.parse(info.budget_reset_at) : NaN
  return {
    id,
    label,
    display: `$${spend.toFixed(2)} / $${budget.toFixed(2)}`,
    remainingPercent: remainingPercent((spend / budget) * 100),
    ...(Number.isFinite(reset) ? { resetAt: Math.floor(reset / 1000) } : {}),
  }
}

const parseLiteLLMUsage = (payload: unknown): QuotaWindow[] => {
  if (!isObject(payload)) throw new Error("user info missing")

  // Personal budget: teams[0].team_memberships[0].litellm_budget_table
  // spend comes from the membership row itself (not the budget table)
  const teams = Array.isArray(payload.teams) ? payload.teams : []
  const firstTeam = teams.find(isObject)
  const memberships = isObject(firstTeam) && Array.isArray(firstTeam.team_memberships)
    ? firstTeam.team_memberships
    : []
  const membership = memberships.find(isObject)
  const budgetTable = isObject(membership) && isObject(membership.litellm_budget_table)
    ? membership.litellm_budget_table
    : undefined

  if (!isObject(membership) || !budgetTable) throw new Error("budget missing")

  const w = parseLiteLLMBudget(
    { ...budgetTable, spend: membership.spend ?? budgetTable.spend },
    "budget",
    "LiteLLM",
  )
  if (!w) throw new Error("budget missing")
  return [w]
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

const liteLLMQuota = (context: Plugin.Context): Effect.Effect<QuotaProvider, unknown> =>
  Effect.gen(function* () {
    const provider = yield* context.provider.get({ providerID: Provider.ID.make("litellm") })
    const baseURL = findBaseURL(provider)
    // The token lives in provider.settings.apiKey (OAuth flow writes it there).
    // Fall back to the integration credential for non-OAuth key setups.
    const token = findApiKey(provider) ?? (yield* Effect.gen(function* () {
      const connection = yield* context.integration.connection.active("litellm")
      if (!connection) return undefined
      const credential = yield* context.integration.connection.resolve(connection)
      return findAccessToken(credential)
    }))
    if (!token || !baseURL) return unavailable("litellm", "LiteLLM")

    const url = liteLLMManagementURL(baseURL)
    const payload = yield* fetchUsage(url, {
      headers: {
        accept: "application/json",
        authorization: `Bearer ${token}`,
      },
    })
    return {
      provider: "litellm",
      name: "LiteLLM",
      status: "ok",
      windows: parseLiteLLMUsage(payload),
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
      yield* context.rpc
        .register(LiteLLMUsage, {
          get: () => quotaHandler("litellm", "LiteLLM", liteLLMQuota(context)),
        })
        .pipe(Effect.orDie)
    }),
})
