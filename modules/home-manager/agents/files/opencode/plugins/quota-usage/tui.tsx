import { Plugin } from "@opencode/plugin/tui"
import { createSignal } from "solid-js"
import { CodexUsage, OpenCodeGoUsage } from "./rpc.js"

export default Plugin.define({
  id: "quota-usage.tui",
  setup(context) {
    const usage = context.client.rpc(CodexUsage)
    const openCodeGoUsage = context.client.rpc(OpenCodeGoUsage)
    const [codexText, setCodexText] = createSignal("CX …")
    const [openCodeGoText, setOpenCodeGoText] = createSignal("GO …")

    const refresh = async () => {
      await Promise.all([
        usage.get({}).then((result) => setCodexText(result.text), () => setCodexText("CX unavailable")),
        openCodeGoUsage.get({}).then(
          (result) => setOpenCodeGoText(result.text),
          () => setOpenCodeGoText("GO unavailable"),
        ),
      ])
    }

    const stopEvents = context.data.listen(({ details }) => {
      if (details.type === "session.execution.succeeded") void refresh()
    })
    const timer = setInterval(() => void refresh(), 60_000)
    const removeCodexStatus = context.ui.slot({
      append: "sidebar.footer",
      render: () => <text fg={context.theme.text.muted}>{codexText()}</text>,
    })
    const removeOpenCodeGoStatus = context.ui.slot({
      append: "sidebar.footer",
      render: () => <text fg={context.theme.text.muted}>{openCodeGoText()}</text>,
    })

    void refresh()
    return () => {
      clearInterval(timer)
      stopEvents()
      removeCodexStatus()
      removeOpenCodeGoStatus()
    }
  },
})
