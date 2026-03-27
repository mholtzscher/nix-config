/**
 * Refine Prompt Extension
 *
 * Provides a `/refine-prompt` workflow that branches into a dedicated
 * refine-promptment scratch space and `/end-refine` to return the refined
 * prompt back to the original branch.
 */

import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";

const REFINE_WIDGET_KEY = "refine-prompt";
const REFINE_BRANCH_LABEL = "refine-prompt";
const REFINE_ANCHOR_LABEL = "refine-prompt-anchor";
const ACTIVE_WIDGET_MESSAGE =
  "Prompt refinement session active, return with /end-refine";
const NO_ACTIVE_SESSION_MESSAGE =
  "Not in a prompt refine branch. Use /refine-prompt first.";
const MISSING_FINAL_SECTION_MESSAGE =
  "Missing required '## Final Refined Prompt' fenced text block in the latest assistant response. Stay in the refine branch and try again.";

const PROMPT_REFINE_STATE_TYPE = "refine-prompt-session";
const PROMPT_REFINE_ANCHOR_TYPE = "refine-prompt-anchor";

type PromptRefineSessionState = {
  active: boolean;
  originId?: string;
};

type AssistantSnapshot = {
  id: string;
  text: string;
};

let promptRefineOriginId: string | undefined;
let isEndingRefine = false;

function setPromptRefineWidget(ctx: ExtensionContext, active: boolean) {
  if (!ctx.hasUI) return;
  if (!active) {
    ctx.ui.setWidget(REFINE_WIDGET_KEY, undefined);
    return;
  }

  ctx.ui.setWidget(REFINE_WIDGET_KEY, (_tui, theme) => {
    const text = new Text(theme.fg("warning", ACTIVE_WIDGET_MESSAGE), 0, 0);
    return {
      render(width: number) {
        return text.render(width);
      },
      invalidate() {
        text.invalidate();
      },
    };
  });
}

function readPromptRefineState(
  ctx: ExtensionContext,
): PromptRefineSessionState | undefined {
  let state: PromptRefineSessionState | undefined;
  for (const entry of ctx.sessionManager.getBranch()) {
    if (
      entry.type === "custom" &&
      entry.customType === PROMPT_REFINE_STATE_TYPE
    ) {
      state = entry.data as PromptRefineSessionState | undefined;
    }
  }

  return state;
}

function persistPromptRefineState(
  pi: ExtensionAPI,
  active: boolean,
  originId?: string,
) {
  pi.appendEntry(
    PROMPT_REFINE_STATE_TYPE,
    active ? { active: true, originId } : { active: false },
  );
}

function activatePromptRefine(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  originId: string,
) {
  promptRefineOriginId = originId;
  setPromptRefineWidget(ctx, true);
  persistPromptRefineState(pi, true, originId);
}

function deactivatePromptRefine(pi: ExtensionAPI, ctx: ExtensionContext) {
  promptRefineOriginId = undefined;
  setPromptRefineWidget(ctx, false);
  persistPromptRefineState(pi, false);
}

function restorePromptRefineState(pi: ExtensionAPI, ctx: ExtensionContext) {
  const state = readPromptRefineState(ctx);

  if (state?.active && state.originId) {
    promptRefineOriginId = state.originId;
    setPromptRefineWidget(ctx, true);
    return;
  }

  promptRefineOriginId = undefined;
  setPromptRefineWidget(ctx, false);

  if (state?.active) {
    persistPromptRefineState(pi, false);
    ctx.ui.notify(
      "Prompt refine state was missing origin info; cleared refine status.",
      "warning",
    );
  }
}

function resolvePromptRefineOrigin(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): string | undefined {
  if (promptRefineOriginId) {
    return promptRefineOriginId;
  }

  const state = readPromptRefineState(ctx);
  if (state?.active && state.originId) {
    promptRefineOriginId = state.originId;
    setPromptRefineWidget(ctx, true);
    return promptRefineOriginId;
  }

  if (state?.active) {
    deactivatePromptRefine(pi, ctx);
    ctx.ui.notify(
      "Prompt refine state was missing origin info; cleared refine status.",
      "warning",
    );
  }

  return undefined;
}

function readLatestAssistantSnapshot(
  ctx: ExtensionContext,
): AssistantSnapshot | null {
  const entries = ctx.sessionManager.getBranch();
  for (let i = entries.length - 1; i >= 0; i--) {
    const entry = entries[i];
    if (entry.type !== "message" || entry.message.role !== "assistant") {
      continue;
    }

    const assistantMessage = entry.message as { content?: unknown };
    return {
      id: entry.id,
      text: extractAssistantTextContent(assistantMessage.content),
    };
  }

  return null;
}

function extractAssistantTextContent(content: unknown): string {
  if (typeof content === "string") {
    return content.trim();
  }

  if (!Array.isArray(content)) {
    return "";
  }

  const textParts = content
    .filter((part): part is { type: "text"; text: string } =>
      Boolean(
        part &&
          typeof part === "object" &&
          "type" in part &&
          part.type === "text" &&
          "text" in part,
      ),
    )
    .map((part) => part.text);

  return textParts.join("\n").trim();
}

function extractFinalRefinedPrompt(messageText: string): string | null {
  const match = messageText.match(
    /(?:^|\r?\n)##\s*Final Refined Prompt\s*\r?\n```text\r?\n([\s\S]*?)\r?\n```\s*$/,
  );
  if (!match) {
    return null;
  }

  return match[1].replace(/^\r?\n+/, "").replace(/\r?\n+$/, "");
}

type LabelableSessionManager = ExtensionContext["sessionManager"] & {
  appendLabelChange?: (targetId: string, label: string | undefined) => void;
};

function createPromptRefineAnchor(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): string | undefined {
  pi.appendEntry(PROMPT_REFINE_ANCHOR_TYPE, {
    createdAt: new Date().toISOString(),
  });
  const leafId = ctx.sessionManager.getLeafId() ?? undefined;
  if (leafId) {
    (ctx.sessionManager as LabelableSessionManager).appendLabelChange?.(
      leafId,
      REFINE_ANCHOR_LABEL,
    );
  }
  return leafId;
}

function buildRefineSeedPrompt(rawPrompt: string): string {
  return [
    "You are a prompt refinement assistant.",
    "",
    "Improve the user's pasted prompt through short, targeted clarification.",
    "Ask only the questions that materially improve the final prompt.",
    "Produce a refined prompt that is ready for direct reuse.",
    "Keep the conversation focused and concise.",
    "",
    "User's raw prompt:",
    "````text",
    rawPrompt,
    "````",
    "",
    "When you have enough information, finish with this exact final section and nothing after it:",
    "## Final Refined Prompt",
    "```text",
    "<final refined prompt here>",
    "```",
  ].join("\n");
}

async function startPromptRefine(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
): Promise<void> {
  if (!ctx.hasUI) {
    ctx.ui.notify("/refine-prompt requires interactive mode", "error");
    return;
  }

  if (readPromptRefineState(ctx)?.active || promptRefineOriginId) {
    ctx.ui.notify(
      "Already in a prompt refine branch. Use /end-refine to finish first.",
      "warning",
    );
    return;
  }

  const rawPrompt = await ctx.ui.editor("Paste the prompt to refine:", "");
  if (rawPrompt === undefined) {
    return;
  }

  const trimmedPrompt = rawPrompt.trim();
  if (!trimmedPrompt) {
    ctx.ui.notify("Prompt refinement requires non-empty input.", "warning");
    return;
  }

  const originId =
    ctx.sessionManager.getLeafId() ?? createPromptRefineAnchor(pi, ctx);
  if (!originId) {
    ctx.ui.notify("Failed to determine prompt refine origin.", "error");
    return;
  }

  promptRefineOriginId = originId;

  try {
    const result = await ctx.navigateTree(originId, {
      summarize: false,
      label: REFINE_BRANCH_LABEL,
    });
    if (result.cancelled) {
      promptRefineOriginId = undefined;
      return;
    }
  } catch (error) {
    promptRefineOriginId = undefined;
    ctx.ui.notify(
      `Failed to start prompt refinement: ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return;
  }

  ctx.ui.setEditorText("");
  activatePromptRefine(pi, ctx, originId);
  pi.sendUserMessage(buildRefineSeedPrompt(trimmedPrompt));
  ctx.ui.notify("Prompt refinement branch started.", "info");
}

async function endPromptRefine(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
): Promise<void> {
  if (!ctx.hasUI) {
    ctx.ui.notify("/end-refine requires interactive mode", "error");
    return;
  }

  if (isEndingRefine) {
    ctx.ui.notify("/end-refine is already running", "info");
    return;
  }

  isEndingRefine = true;
  try {
    const originId = resolvePromptRefineOrigin(pi, ctx);
    if (!originId) {
      if (!readPromptRefineState(ctx)?.active) {
        ctx.ui.notify(NO_ACTIVE_SESSION_MESSAGE, "info");
      }
      return;
    }

    const assistantSnapshot = readLatestAssistantSnapshot(ctx);
    if (!assistantSnapshot) {
      ctx.ui.notify(
        "No assistant response found in the refine branch yet.",
        "error",
      );
      return;
    }

    const extractedPrompt = extractFinalRefinedPrompt(assistantSnapshot.text);
    if (!extractedPrompt) {
      ctx.ui.notify(MISSING_FINAL_SECTION_MESSAGE, "error");
      return;
    }

    try {
      const result = await ctx.navigateTree(originId, { summarize: false });
      if (result.cancelled) {
        ctx.ui.notify(
          "Navigation cancelled. Use /end-refine to try again.",
          "info",
        );
        return;
      }
    } catch (error) {
      ctx.ui.notify(
        `Failed to return to the original branch: ${error instanceof Error ? error.message : String(error)}`,
        "error",
      );
      return;
    }

    pi.sendUserMessage(extractedPrompt, { deliverAs: "followUp" });
    deactivatePromptRefine(pi, ctx);
    ctx.ui.notify(
      "Prompt refinement complete! Returned to the original branch.",
      "info",
    );
  } finally {
    isEndingRefine = false;
  }
}

export default function refinePromptExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    restorePromptRefineState(pi, ctx);
  });

  pi.on("session_switch", (_event, ctx) => {
    restorePromptRefineState(pi, ctx);
  });

  pi.on("session_tree", (_event, ctx) => {
    restorePromptRefineState(pi, ctx);
  });

  pi.registerCommand("refine-prompt", {
    description: "Start a dedicated prompt refinement branch",
    handler: async (_args, ctx) => {
      await startPromptRefine(pi, ctx);
    },
  });

  pi.registerCommand("end-refine", {
    description:
      "Return from prompt refinement and send back the refined prompt",
    handler: async (_args, ctx) => {
      await endPromptRefine(pi, ctx);
    },
  });
}
