# NIXOS DESKTOP MODULE KNOWLEDGE

## OVERVIEW
Desktop-only NixOS module bundle: composition, gaming, packages, webapps, EDID assets.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add desktop package | `packages.nix` | System-level package and font defaults |
| Tune compositor/keybinds | `composition.nix` | Niri + DMS integration lives here |
| Tune gaming stack | `gaming.nix` | MangoHud/peripheral/game tooling |
| Add webapp wrappers | `webapps.nix` | Uses HM `programs.webapps` module |
| Update monitor EDID | `edid/` + `hosts/.../gpu.nix` | GPU host config references these assets |

## CONVENTIONS
- Keep this directory desktop-specific; no generic NixOS settings here.
- Desktop behavior is injected when `graphical = true` in `lib/default.nix`.
- Cross-module HM customizations should use `home-manager.sharedModules` blocks.
- Prefer declarative keybind/window rules over ad-hoc scripts.

## ANTI-PATTERNS (THIS DIRECTORY)
- Assuming these modules are host-agnostic; current loader hardwires this path for graphical Linux hosts.
- Moving host hardware concerns here when they belong in `hosts/nixos/nixos-desktop/`.
- Letting EDID docs drift from actual directory-based host layout.
- Massive commented blocks left stale in compositor/webapps config.

## VALIDATION
```bash
nix flake check
nixos-rebuild build --flake ~/.config/nix-config#nixos-desktop
```
