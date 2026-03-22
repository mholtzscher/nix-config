import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const shutdown = (ctx: { shutdown: () => void }) => {
    ctx.shutdown();
  };

  pi.registerCommand("exit", {
    description: "Exit pi cleanly",
    handler: async (_args, ctx) => {
      shutdown(ctx);
    },
  });

  pi.on("input", async (event, ctx) => {
    if (event.text.trim() === ":q") {
      shutdown(ctx);
      return { action: "handled" as const };
    }

    return { action: "continue" as const };
  });
}
