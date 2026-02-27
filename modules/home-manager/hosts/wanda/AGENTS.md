# WANDA HOST-MANAGER KNOWLEDGE

## OVERVIEW
Ubuntu server home-manager overrides for `wanda`, including headless program policy and container model.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Host-specific packages | `default.nix` | CLI tools and host-only package deltas |
| Headless overrides | `default.nix` | Uses `lib.mkForce false` for GUI modules |
| Git/SSH host identity | `default.nix` | Local user identity + match blocks |
| Container definitions | `containers.nix` | Typed Nix model for future compose generation |

## CONVENTIONS
- Keep Wanda-specific behavior here; shared defaults stay in global HM modules.
- Prefer explicit `mkForce` for disabling GUI modules inherited from shared config.
- In `containers.nix`, model services in `containers` attrset; derive compose output via helpers.
- Keep data paths under `/srv` unless intentional migration.

## ANTI-PATTERNS (THIS DIRECTORY)
- Mixing host-agnostic defaults into Wanda overrides.
- Hand-editing generated compose output instead of changing Nix data model.
- Introducing GUI assumptions in a headless server profile.
- Adding container env secrets directly in repo files.

## VALIDATION
```bash
nix flake check
home-manager build --flake ~/.config/nix-config#wanda
```
