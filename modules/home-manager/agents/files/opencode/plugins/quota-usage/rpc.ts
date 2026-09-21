import { Rpc } from "@opencode/plugin/rpc"

export type QuotaWindow = {
  id: string
  label: string
  remainingPercent: number
  resetAt?: number
}

export type QuotaProvider = {
  provider: "codex" | "opencode-go" | "litellm"
  name: string
  status: "ok" | "unavailable"
  windows: QuotaWindow[]
  message?: string
  fetchedAt: number
}

const quotaOutput = {
  type: "object",
  properties: {
    provider: { type: "string", enum: ["codex", "opencode-go", "litellm"] },
    name: { type: "string" },
    status: { type: "string", enum: ["ok", "unavailable"] },
    windows: {
      type: "array",
      items: {
        type: "object",
        properties: {
          id: { type: "string" },
          label: { type: "string" },
          remainingPercent: { type: "number" },
          resetAt: { type: "number" },
        },
        required: ["id", "label", "remainingPercent"],
        additionalProperties: false,
      },
    },
    message: { type: "string" },
    fetchedAt: { type: "number" },
  },
  required: ["provider", "name", "status", "windows", "fetchedAt"],
  additionalProperties: false,
} as const

const quotaMethod = {
  input: {
    type: "object",
    properties: {},
    additionalProperties: false,
  },
  output: quotaOutput,
  errors: {},
} as const

export const CodexUsage = Rpc.define({
  id: "codex-usage",
  methods: { get: quotaMethod },
  events: {},
})

export const OpenCodeGoUsage = Rpc.define({
  id: "opencode-go-usage",
  methods: { get: quotaMethod },
  events: {},
})

export const LiteLLMUsage = Rpc.define({
  id: "litellm-usage",
  methods: { get: quotaMethod },
  events: {},
})
