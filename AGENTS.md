# PROJECT KNOWLEDGE BASE

## OVERVIEW

Personal multi-platform Nix flake for 2 Darwin hosts, 1 NixOS desktop, 1 Ubuntu home-manager host.
Core flow: `flake.nix` declares hosts, `lib/default.nix` builds systems and injects shared module args, `modules/` carries shared/platform/host behavior.

## STRUCTURE

```text
.
|- flake.nix                           # host registry + flake inputs
|- lib/default.nix                    # mkSystem / mkHome
|- hosts/                             # per-host entrypoints
|  |- darwin/
|  |- nixos/
|  `- ubuntu/
|- modules/
|  |- darwin/                         # macOS system + Homebrew
|  |- nixos/                          # NixOS system + desktop host modules
|  |- shared/                         # cross-platform system settings
|  `- home-manager/
|     |- programs/                    # shared program modules
|     |- hosts/                       # per-host user config
|     `- files/                       # managed dotfiles/assets/opencode config
|- pkgs/                              # custom packages
`- infrastructure/                    # Terraform placeholder; mostly empty
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add or edit a host | `hosts/` + matching `modules/home-manager/hosts/` | NixOS hosts may also need `modules/nixos/hosts/` |
| Change builder behavior | `lib/default.nix` | `mkSystem` and `mkHome` are source of truth |
| Shared packages | `modules/home-manager/packages.nix` | Use host files for machine-only packages |
| Shared program config | `modules/home-manager/programs/` | See local guide in `modules/home-manager/programs/AGENTS.md` |
| Darwin defaults / Homebrew | `modules/darwin/` | Platform-only; keep guards clean |
| NixOS desktop UX / gaming | `modules/nixos/hosts/nixos-desktop/` | See local guide there |
| OpenCode config | `modules/home-manager/programs/opencode.nix` + `modules/home-manager/files/opencode/` | Program wiring vs shipped config tree |
| Ubuntu containers | `modules/home-manager/hosts/wanda/containers.nix` | Structured Nix data -> compose YAML |

## CONVENTIONS

- Prefer `mkSystem` / `mkHome`; do not hand-roll host assembly.
- Prefer module args `isDarwin`, `isLinux`, `graphical`, `gaming`, `isWork` over ad hoc platform checks.
- Split overrides by boundary: host entry in `hosts/`, user overrides in `modules/home-manager/hosts/`, system overrides in `modules/nixos/hosts/`, Homebrew overrides in `modules/darwin/homebrew/hosts/`.
- NixOS desktop user-session config often enters via `home-manager.sharedModules`; system/user split is intentional.
- `modules/home-manager/files/` is not just text dotfiles; it also stores assets, scripts, opencode content, wallpapers, shaders.

## ANTI-PATTERNS

- Never apply Nix changes from agent flow; validate only.
- Never run `nfu` / `nix flake update` unless user asked.
- Never put macOS-only features outside guards or `modules/darwin/`.
- Never move host-specific state into shared modules just to avoid one extra file.
- Do not create Terraform-specific guidance under `infrastructure/` until real infra code exists.

## UNIQUE STYLES

- Shell helpers are part of repo API: `nb`, `nbt`, `nup`, `nupt`, `nfu`, `nf`, `tst`, `gtest`, `ai_commit`.
- OpenCode agents, commands, skills, and plugins live inside the repo and are synced by home-manager.
- `wanda` container config models services as Nix data first, then renders compose YAML later.

## COMMANDS

```bash
nix flake check        # safe cross-platform validation
nb                     # platform-aware validate helper
nf                     # format all .nix files under CWD
nfu                    # flake update; only when requested
```

## NOTES

- Root doc is umbrella. Prefer child docs when present.
- Existing high-signal child docs:
  - `modules/home-manager/programs/AGENTS.md`
  - `modules/nixos/hosts/nixos-desktop/AGENTS.md`
  - `modules/home-manager/files/opencode/AGENTS.md`
