import { Plugin } from "@opencode/plugin/tui"
import { For, Show, createSignal } from "solid-js"
import { CodexUsage, OpenCodeGoUsage } from "./rpc.js"
import type { QuotaProvider, QuotaWindow } from "./rpc.js"

const fallbackProvider = (
  provider: QuotaProvider["provider"],
  name: string,
): QuotaProvider => ({
  provider,
  name,
  status: "unavailable",
  windows: [],
  message: "Usage unavailable",
  fetchedAt: Date.now(),
})

const formatCountdown = (resetAt: number | undefined, now: number): string | undefined => {
  if (resetAt === undefined) return undefined
  const minutes = Math.max(0, Math.floor((resetAt * 1000 - now) / 60_000))
  const days = Math.floor(minutes / 1440)
  const hours = Math.floor((minutes % 1440) / 60)
  if (days > 0) return `${days}d${hours > 0 ? ` ${hours}h` : ""}`
  if (hours > 0) return `${hours}h ${minutes % 60}m`
  return `${minutes}m`
}

export default Plugin.define({
  id: "quota-usage.tui",
  setup(context) {
    const location = context.location ?? context.data.location.default()
    const codex = context.client.rpc(CodexUsage)
    const openCodeGo = context.client.rpc(OpenCodeGoUsage)
    const [providers, setProviders] = createSignal<QuotaProvider[]>([])
    const [now, setNow] = createSignal(Date.now())
    let refreshing = false

    const tone = (remaining: number) => {
      if (remaining <= 10) {
        return context.theme.text.feedback?.error?.base ?? context.theme.hue.red[500]
      }
      if (remaining <= 30) {
        return context.theme.text.feedback?.warning?.base ?? context.theme.hue.yellow[500]
      }
      return context.theme.text.feedback?.success?.base ?? context.theme.hue.green[500]
    }

    const QuotaCard = (props: { window: QuotaWindow }) => {
      const reset = () => formatCountdown(props.window.resetAt, now())
      return (
        <box
          width="30%"
          flexGrow={1}
          flexDirection="column"
          border
          borderColor={context.theme.border.base}
          paddingLeft={1}
          paddingRight={1}
        >
          <text fg={context.theme.text.muted} wrapMode="none" truncate>
            {props.window.label.toUpperCase()}
          </text>
          <text fg={tone(props.window.remainingPercent)}>
            <b>{props.window.display ?? `${props.window.remainingPercent.toFixed(0)}%`}</b>
          </text>
          <Show when={reset()}>
            {(value) => <text fg={context.theme.text.muted} wrapMode="none" truncate>{value()}</text>}
          </Show>
        </box>
      )
    }

    const ProviderQuota = (props: { provider: QuotaProvider }) => {
      const singleWindow = () => props.provider.windows.length === 1
      const primaryWindow = () => props.provider.windows[0]
      const primaryReset = () => formatCountdown(primaryWindow()?.resetAt, now())
      return (
        <box width="100%" flexDirection="column" gap={1}>
          <Show
            when={props.provider.status === "ok" && props.provider.windows.length > 0}
            fallback={
              <box width="100%" flexDirection="column">
                <text fg={context.theme.text.base}><b>{props.provider.name}</b></text>
                <text fg={context.theme.text.muted}>{props.provider.message ?? "Usage unavailable"}</text>
              </box>
            }
          >
            <Show
              when={singleWindow()}
              fallback={
                <box width="100%" flexDirection="column">
                  <text fg={context.theme.text.base}><b>{props.provider.name}</b></text>
                  <box width="100%" flexDirection="row" gap={1}>
                    <For each={props.provider.windows}>
                      {(window) => <QuotaCard window={window} />}
                    </For>
                  </box>
                </box>
              }
            >
              <box width="100%" flexDirection="row" justifyContent="space-between">
                <text fg={context.theme.text.base}><b>{props.provider.name}</b></text>
                <box flexDirection="row" gap={1}>
                  <text fg={tone(primaryWindow()!.remainingPercent)}>
                    <b>{primaryWindow()!.display ?? `${primaryWindow()!.remainingPercent.toFixed(0)}%`}</b>
                  </text>
                  <Show when={primaryReset()}>
                    {(value) => <text fg={context.theme.text.muted}>· {value()}</text>}
                  </Show>
                </box>
              </box>
            </Show>
          </Show>
        </box>
      )
    }

    const refresh = async () => {
      if (refreshing) return
      refreshing = true
      try {
        await context.data.location.provider.sync(location)
        const configured = new Set(
          (context.data.location.provider.list(location) ?? []).map((provider) => provider.id),
        )
        const requests: Promise<QuotaProvider>[] = []
        if (configured.has("openai")) {
          requests.push(codex.get({}).then(
            (value) => value as QuotaProvider,
            () => fallbackProvider("codex", "Codex"),
          ))
        }
        if (configured.has("opencode-go")) {
          requests.push(openCodeGo.get({}).then(
            (value) => value as QuotaProvider,
            () => fallbackProvider("opencode-go", "OpenCode Go"),
          ))
        }
        setProviders(await Promise.all(requests))
      } finally {
        refreshing = false
      }
    }

    const stopEvents = context.data.listen(({ details }) => {
      if (details.type === "session.execution.succeeded") void refresh()
    })
    const refreshTimer = setInterval(() => void refresh(), 60_000)
    const countdownTimer = setInterval(() => setNow(Date.now()), 60_000)
    const removeQuotaPanel = context.ui.slot({
      append: "sidebar.content",
      render: () => (
        <Show when={providers().length > 0}>
          <box
            width="100%"
            flexDirection="column"
            gap={1}
            border
            borderStyle="rounded"
            borderColor={context.theme.border.base}
            title="Quotas"
            titleColor={context.theme.text.base}
            paddingLeft={1}
            paddingRight={1}
          >
            <For each={providers()}>
              {(provider) => <ProviderQuota provider={provider} />}
            </For>
          </box>
        </Show>
      ),
    })

    void refresh()
    return () => {
      clearInterval(refreshTimer)
      clearInterval(countdownTimer)
      stopEvents()
      removeQuotaPanel()
    }
  },
})
