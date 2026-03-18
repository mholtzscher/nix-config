# NIXOS DESKTOP

## OVERVIEW

Desktop-only NixOS host layer for `nixos-desktop`: composition, gaming extras, desktop packages, webapps, and local KVM/EDID assets.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| See import boundary | `default.nix` | Registry for this host subtree |
| Add desktop system packages / fonts / 1Password | `packages.nix` | System-level only |
| Change Niri / DMS / monitor / keybind behavior | `composition.nix` | Injects user-session config via `home-manager.sharedModules` |
| Change gaming extras | `gaming.nix` | Ratbagd + MangoHud + HM gaming packages; coordinate with host entry for system toggles |
| Change desktop web apps | `webapps.nix` | Home-manager program config injected here |
| KVM display quirks | `edid/` | Hardware-local assets and capture helper |

## STRUCTURE

```text
nixos-desktop/
|- default.nix         # import registry
|- packages.nix        # system packages + fonts + 1Password
|- composition.nix     # Niri + DMS + monitor/keybind rules
|- gaming.nix          # gaming user packages + MangoHud
|- webapps.nix         # desktop webapps list
`- edid/               # monitor blob + capture notes
```

## CONVENTIONS

- Keep desktop-only behavior here; shared modules stay platform-wide.
- Push user-session settings through `home-manager.sharedModules` when system module owns the feature.
- Keep monitor-specific and KVM-specific assets local to this dir.
- `graphical = true` in `lib/default.nix` is what pulls this subtree in.
- Let DMS own wallpaper/backdrop behavior; Niri layout stays transparent for that integration.

## ANTI-PATTERNS

- Do not move machine-local monitor rules into shared home-manager config.
- Do not add generic Linux packages here if they are not desktop-specific.
- Do not treat `gaming.nix` as the place for host-level Steam or gamemode toggles owned by `hosts/nixos/nixos-desktop/default.nix`.
- Do not edit `edid/dp1.bin` casually; recapture intentionally with the helper if hardware changes.
