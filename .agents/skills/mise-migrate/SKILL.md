---
name: mise-migrate
description: Migrate a named tool or dotfile from this Nix configuration to the Mise workstation setup.
---

Migrate only the requested target (e.g. `@mise-migrate justfile`); distinguish a file/task migration from installing its CLI.

1. Inspect Nix ownership, live settings, and `~/.config/mise/config.toml`, including extensions, aliases, and integrations. Agree on keep/migrate/remove for affected companions before deleting their ownership. Preserve personal/work/platform selection.
2. Prefer `mise registry <tool>` for the correct product/version; otherwise inspect upstream packaging before selecting a backend. Check bootstrap package managers for extensions; encode registration in repeatable bootstrap steps, not manual-only commands. Verify executable names and supported platforms.
3. Add tools with `auto_update = true`. Before the switch, stage exact non-secret config contents independently of Nix symlinks, or verify the chosen workstation version exists. Recovery backups are optional; replacement contents must be available. Track regular writable files with `[dotfiles]` / `mode = "track"`; exclude credentials and runtime state.
4. Remove corresponding Nix ownership and newly unused inputs; validate via `docs/NIX_WORKFLOW.md`. Only the user applies Nix. Say **staged**, explain which files activation removes, and ask for the switch plus confirmation—not a list of remaining agent-executable chores.
5. After confirmation, verify activation, restore missing configs from the staged contents, resolve confirmed leftover Nix links, and install/register the replacements. Preserve unexpected local edits. Check requested removals for leftover registrations, aliases, and configs.
6. Verify command resolution, settings, and extensions in a fresh shell. Run `mise dot save` and `mise dot sync`; confirm portable regular files in `mholtzscher/workstation` before declaring completion. Its local checkout is a saved view, not the live config source.

Report completion or the exact remaining user-run step in chat. Create no handoff docs.
