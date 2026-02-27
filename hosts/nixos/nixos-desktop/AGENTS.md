# NIXOS DESKTOP HOST KNOWLEDGE

## OVERVIEW
System-level host configuration for `nixos-desktop`: hardware, boot, networking, audio, GPU, users.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add core host setting | `default.nix` | Imports and host-only baseline options |
| Hardware changes | `hardware-configuration.nix` | Generated file; edit carefully |
| Boot behavior | `boot.nix` | Loader/kernel boot-time settings |
| GPU/display setup | `gpu.nix` | NVIDIA + EDID references |
| Network/firewall | `networking.nix` | Interfaces, DNS, firewall policy |
| Users/sudo/groups | `users.nix` | Account and privilege setup |
| Audio stack | `audio.nix` | PipeWire/Pulse/JACK choices |
| Greeter/login | `greeter.nix` | Display manager integration |

## CONVENTIONS
- Keep host infra concerns here; desktop UX behavior belongs in `modules/nixos/hosts/nixos-desktop/`.
- Home-manager host wiring stays in this host root via `home-manager.users.${user}` imports.
- Keep imports granular (one concern per file) and referenced from `default.nix`.
- Preserve declarative ownership/permission fixes with `systemd.tmpfiles.rules` when needed.

## ANTI-PATTERNS (THIS DIRECTORY)
- Packing unrelated host concerns into one large file.
- Editing generated hardware config without re-validating full host build.
- Duplicating settings already provided in shared modules.
- Moving host-specific paths/IDs into shared modules.

## VALIDATION
```bash
nix flake check
nixos-rebuild build --flake ~/.config/nix-config#nixos-desktop
```
