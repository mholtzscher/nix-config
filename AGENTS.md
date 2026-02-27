# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-26 21:35:13 CST  
**Commit:** 9fa698c  
**Branch:** main

## OVERVIEW
Multi-platform Nix flake for macOS, NixOS, Ubuntu home-manager.
Core orchestration in `flake.nix` + `lib/default.nix`; most behavior in `modules/*`.

## STRUCTURE
```text
./
├── flake.nix                                  # Host entrypoint map
├── lib/default.nix                            # mkSystem/mkHome orchestration
├── hosts/
│   ├── darwin/*/default.nix                   # Per-host darwin roots
│   ├── nixos/nixos-desktop/                   # Desktop host root + hardware split
│   └── ubuntu/wanda/default.nix               # Standalone HM host root
├── modules/
│   ├── shared/                                # Cross-platform system settings
│   ├── darwin/                                # macOS system + homebrew
│   ├── nixos/                                 # NixOS base + desktop host modules
│   └── home-manager/                          # User layer + files/programs/hosts
└── modules/home-manager/files/opencode/       # Agent/skill payload + policies
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add/change host | `flake.nix` + `hosts/<platform>/<host>/default.nix` | Keep host names aligned across trees |
| Change module graph | `lib/default.nix` | `graphical=true` currently hardwires desktop host modules |
| User programs | `modules/home-manager/programs/` | Also update `programs/default.nix` imports |
| NixOS desktop behavior | `modules/nixos/hosts/nixos-desktop/` | Niri/DMS/gaming/webapps |
| Host infra settings | `hosts/nixos/nixos-desktop/` | boot/gpu/networking/audio/users |
| Server containers (Wanda) | `modules/home-manager/hosts/wanda/containers.nix` | Nix data model for compose generation |
| Agent tooling content | `modules/home-manager/files/opencode/` | Local policy layer + skills/agents/commands |

## HIERARCHY
- `AGENTS.md` (root)
- `modules/home-manager/files/opencode/AGENTS.md`
- `modules/home-manager/programs/AGENTS.md`
- `modules/home-manager/files/AGENTS.md`
- `modules/home-manager/files/opencode/skills/AGENTS.md`
- `modules/nixos/hosts/nixos-desktop/AGENTS.md`
- `hosts/nixos/nixos-desktop/AGENTS.md`
- `modules/home-manager/hosts/wanda/AGENTS.md`

## CONVENTIONS
- Validate only. Do not apply system changes from agent runs.
- Safe checks: `nix flake check`, `darwin-rebuild build --flake ~/.config/nix-config`.
- Use module args (`isDarwin`, `isLinux`, `isWork`, `graphical`, `gaming`), avoid ad-hoc platform checks.
- Keep platform split in `modules/{darwin,nixos,shared}`; keep host intent in `hosts/*` and `modules/*/hosts/*`.
- Treat `modules/home-manager/files/` as source-of-truth assets; wire through modules, not manual copies.

## ANTI-PATTERNS (THIS PROJECT)
- Running `darwin-rebuild switch`/`nup`/`sudo darwin-rebuild switch` without explicit user approval.
- Adding `*.nix` module files without wiring imports in corresponding `default.nix`.
- Assuming `graphical=true` is host-agnostic; today it implies `modules/nixos/hosts/nixos-desktop`.
- Hardcoding one-off behavior where `isWork`/platform guards already model the branch.
- Letting docs drift from directory-based host layout (`hosts/<platform>/<host>/default.nix`).

## UNIQUE STYLES
- Directory-as-module pattern (`default.nix` roots) used consistently for hosts/modules.
- Host policy split: system-level host config in `hosts/*`, user-level host config in `modules/home-manager/hosts/*`.
- Opencode subtree has its own local AGENTS constraints and skill-driven workflows.

## COMMANDS
```bash
nix flake check
darwin-rebuild build --flake ~/.config/nix-config
nixos-rebuild build --flake ~/.config/nix-config#nixos-desktop
```

## NOTES
- No CI workflow present; validation is local-first.
- `result` symlink may exist from local builds; treat as artifact.
