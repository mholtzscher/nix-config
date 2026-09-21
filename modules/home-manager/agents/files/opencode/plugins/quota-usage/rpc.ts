import { Rpc } from "@opencode/plugin/rpc"

// Provider-specific RPC IDs let each quota source refresh independently.

export const CodexUsage = Rpc.define({
  id: "codex-usage",
  methods: {
    get: {
      input: {
        type: "object",
        properties: {},
        additionalProperties: false,
      },
      output: {
        type: "object",
        properties: { text: { type: "string" } },
        required: ["text"],
        additionalProperties: false,
      },
      errors: {},
    },
  },
  events: {},
})

export const OpenCodeGoUsage = Rpc.define({
  id: "opencode-go-usage",
  methods: {
    get: {
      input: {
        type: "object",
        properties: {},
        additionalProperties: false,
      },
      output: {
        type: "object",
        properties: { text: { type: "string" } },
        required: ["text"],
        additionalProperties: false,
      },
      errors: {},
    },
  },
  events: {},
})
