# tmux Cheatsheet for Zellij Muscle Memory

This setup intentionally keeps tmux close to its defaults. The main mental shift is:

- **Zellij:** modal actions start from `Ctrl-g`, then a mode key like `p`, `t`, `s`, `r`, or `o`.
- **tmux:** most actions start from the **prefix**, which is the default `Ctrl-b`, then one command key.

`prefix` below means: press `Ctrl-b`, release, then press the next key.

## Core actions

| What you did in Zellij | Zellij binding | tmux default / current equivalent |
| --- | --- | --- |
| Enter command mode | `Ctrl-g` | `prefix` / `Ctrl-b` |
| Detach session | `Ctrl-g` → `o` → `d` | `prefix d` |
| Quit / close client | `Ctrl-q` | `prefix d`, or shell `exit` |
| Show key help | Zellij mode hints | `prefix ?` |
| Reload config | n/a | `prefix : source-file ~/.config/tmux/tmux.conf` |

## Panes

| What you did in Zellij | Zellij binding | tmux default / current equivalent |
| --- | --- | --- |
| New pane | `Alt-n` or `Ctrl-g` → `p` → `n` | `prefix %` for side-by-side split, `prefix "` for top/bottom split |
| New pane down | `Ctrl-g` → `p` → `d` | `prefix "` |
| New pane right | `Ctrl-g` → `p` → `r` | `prefix %` |
| Move focus left/right/up/down | `Alt-h/j/k/l` or pane mode `h/j/k/l` | `prefix ←/↓/↑/→`; mouse click also works |
| Cycle panes | `Ctrl-g` → `p` → `Tab` | `prefix o` |
| Previous pane | n/a | `prefix ;` |
| Close focused pane | `Ctrl-g` → `p` → `x` | `prefix x` |
| Fullscreen / zoom pane | `Ctrl-g` → `p` → `f` | `prefix z` |
| Move/swap pane | `Ctrl-g` → `m` → direction | `prefix {` / `prefix }` |
| Resize pane | `Ctrl-g` → `r` → arrows/hjkl | `prefix Ctrl-←/↓/↑/→`, or drag pane borders with mouse |

## Tabs vs windows

Zellij tabs map most closely to tmux windows.

| What you did in Zellij | Zellij binding | tmux default / current equivalent |
| --- | --- | --- |
| New tab | `Alt-t` or `Ctrl-g` → `t` → `n` | `prefix c` |
| Next tab/window | `Alt-l` at edge, or tab mode `l/j` | `prefix n` |
| Previous tab/window | `Alt-h` at edge, or tab mode `h/k` | `prefix p` |
| Jump to tab/window number | `Ctrl-g` → `t` → `1..9` | `prefix 0..9` |
| Rename tab/window | `Ctrl-g` → `t` → `r` | `prefix ,` |
| Close tab/window | `Ctrl-g` → `t` → `x` | `prefix &` |
| List tabs/windows | Session/tab manager | `prefix w` |

## Sessions

| What you did in Zellij | Zellij binding | tmux default / current equivalent |
| --- | --- | --- |
| Session manager | `Ctrl-g` → `o` → `w` / `Alt-z` | `prefix s` |
| Detach | `Ctrl-g` → `o` → `d` | `prefix d` |
| Rename session | n/a | `prefix $` |
| Attach from shell | `zellij attach` / sessionizer | `tmux attach`, `tmux ls`, `tmux new -s name`, `tmux attach -t name` |

## Scrollback, copy, and search

| What you did in Zellij | Zellij binding | tmux default / current equivalent |
| --- | --- | --- |
| Enter scroll mode | `Ctrl-g` → `s` | `prefix [` |
| Scroll up/down | `j/k`, arrows, page keys | vi copy-mode keys, arrows, PageUp/PageDown |
| Search scrollback | `Ctrl-g` → `s` → `f` | `prefix [` then `/` search forward or `?` search backward |
| Copy selection | Zellij selection/copy | `prefix [` then vi selection; `tmux-yank` adds clipboard-friendly yank behavior |

## Floating panes / popups

Zellij floating panes do not have a perfect tmux equivalent.

| Zellij feature | tmux equivalent |
| --- | --- |
| Floating panes | tmux popups, but only when explicitly bound or run from command mode |
| Plugin panes like sessionizer | Usually custom `display-popup` bindings or external shell scripts |
| Current config | Intentionally no popup bindings yet, to keep tmux default/minimal |

If you miss this later, the first custom binding I would add is a single session picker popup rather than recreating all Zellij bindings.

## Plugin mapping

| Zellij-ish capability | tmux plugin / setup | What it gives you |
| --- | --- | --- |
| Catppuccin theme continuity | `catppuccin.tmux.enable = true` | Theme managed by the existing Catppuccin flake/module |
| Session persistence / resurrectable sessions | `tmux-resurrect` | Manual save/restore of tmux sessions, windows, panes, layouts, and commands |
| Auto-save sessions | `tmux-continuum` | Periodic session saves; can auto-restore depending on plugin defaults/config |
| Vim/editor pane navigation | `vim-tmux-navigator` | `Ctrl-h/j/k/l` style navigation between Vim splits and tmux panes, assuming editor-side config is present |
| Clipboard ergonomics | `tmux-yank` | Easier copy-mode yanking to system clipboard |
| Sensible defaults | `sensibleOnTop = true` | Home Manager loads `tmux-sensible` before other plugins |

## Current minimal config summary

The repo currently enables only:

- tmux
- mouse support
- tmux sensible defaults
- Catppuccin tmux theme via the Catppuccin module
- `resurrect`, `continuum`, `vim-tmux-navigator`, and `yank`

Everything else is intentionally left as tmux default behavior.
