/**
 * Nix Switch Blocker Extension
 *
 * Blocks dangerous Nix switch commands that would apply system changes.
 * Allows build commands for validation but prevents activation.
 */

import type { ExtensionAPI, ToolCallEvent } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

// Commands that are forbidden - must match at start of command or after common prefixes
const BLOCKED_PATTERNS = [
  /^darwin-rebuild\s+switch/,
  /^sudo\s+darwin-rebuild\s+switch/,
  /^nixos-rebuild\s+switch/,
  /^sudo\s+nixos-rebuild\s+switch/,
  /^home-manager\s+switch/,
  /\bnup\b/, // Common macOS nix update + switch alias (word boundary)
  /\bnupt\b/, // Variation of nup alias
];

// Commands that are allowed (for validation)
const ALLOWED_PATTERNS = [
  /^darwin-rebuild\s+build/,
  /^nixos-rebuild\s+build/,
  /^home-manager\s+build/,
];

function matchesPattern(command: string, patterns: RegExp[]): boolean {
  const trimmed = command.trim();
  return patterns.some(pattern => pattern.test(trimmed));
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event: ToolCallEvent, ctx) => {
    // Only intercept bash tool calls
    if (!isToolCallEventType("bash", event)) {
      return undefined;
    }

    const command = event.input.command || "";

    // Check if this is a blocked switch command (nix rebuild commands)
    if (matchesPattern(command, BLOCKED_PATTERNS)) {
      // Notify user if UI is available
      if (ctx.hasUI) {
        ctx.ui.notify(
          `Blocked: Nix switch commands cannot be run by the agent`,
          "warning"
        );
      }

      return {
        block: true,
        reason: `Nix switch commands are blocked by AGENTS.md safety policy. Use 'build' instead of 'switch' for validation, or run switch commands manually outside of the agent.`,
      };
    }

    return undefined;
  });

  // Log extension load
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.hasUI) {
      ctx.ui.notify("Nix switch blocker active", "info");
    }
  });
}
