# FILE ASSETS KNOWLEDGE

## OVERVIEW
Canonical asset payloads for home-manager modules. Mix of dotfiles, scripts, media, and opencode content.

## STRUCTURE
```text
modules/home-manager/files/
├── opencode/               # Agent policies, skills, commands, tools
├── raycast/                # macOS-only Raycast scripts
├── nushell/                # Shared Nushell function library
├── neovim/                 # Neovim init payload
├── ghostty/shaders/        # Ghostty shader assets
├── wallpapers/             # Desktop wallpaper assets
└── topiary/                # Nushell grammar formatting config
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add shared dotfile | `modules/home-manager/files/` + reference from `home.nix` | Files here are source-of-truth |
| Add executable helper | `modules/home-manager/files/<script>` | Wire executable flags where linked |
| Add macOS Raycast action | `modules/home-manager/files/raycast/*.sh` + `home.nix` | Guarded by `isDarwin` |
| Update shell workflows | `modules/home-manager/files/nushell/functions.nu` | Keep behavior synced with zsh wrappers |
| Update opencode behavior | `modules/home-manager/files/opencode/` | See local AGENTS under opencode |

## CONVENTIONS
- Treat this directory as immutable source assets consumed by modules.
- Wire all additions through Nix modules (`home.nix`, `programs/*.nix`); do not rely on manual copies.
- Keep platform-specific files behind platform guards at usage site.
- Prefer explicit executable bits where scripts are mapped to `bin/` or XDG targets.

## ANTI-PATTERNS (THIS DIRECTORY)
- Editing generated targets in `$HOME` instead of source files here.
- Adding files with no referencing module path.
- Duplicating same script/config payload across multiple files instead of shared source.
- Embedding secrets/env files in this tree.

## VALIDATION
```bash
nix flake check
darwin-rebuild build --flake ~/.config/nix-config
```
