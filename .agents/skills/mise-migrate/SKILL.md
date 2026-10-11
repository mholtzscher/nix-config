---
name: mise-migrate
description: Migrate a named tool or dotfile from this Nix configuration to the Mise workstation setup.
---

Migrate only the requested target (e.g. `@mise-migrate justfile`); distinguish a file/task migration from installing its CLI.

1. Follow repository instructions. Inspect current Nix ownership, live settings, and `~/.config/mise/config.toml`. Preserve behavior and personal/work/platform selection.
2. Prefer `mise registry <tool>` when it supplies the correct product/version. Otherwise retain an explicit backend. Add tool declarations with `auto_update = true`; enroll selected writable files under `[dotfiles]` with `mode = "track"`. Keep credentials and runtime state outside tracking.
3. Remove the corresponding Nix ownership and only newly unused inputs. Validate via `docs/NIX_WORKFLOW.md`. Only the user applies Nix; pause at that boundary when needed.
4. After activation, inspect leftover links before replacing them. Preserve current settings unless the user chooses workstation versions. Capture regular file contents, never Nix-store symlinks; backups are optional.
5. Install and verify the tool and config in a fresh shell. Run `mise dot save` and `mise dot sync`; confirm the saved files in `mholtzscher/workstation` are portable. A local checkout is a saved view, not the live config source.

Report completion or the exact remaining user-run step in chat. Create no handoff docs.
