# PROGRAM MODULES KNOWLEDGE

## OVERVIEW
Home-manager program modules. Large flat directory, heavy cross-platform gating.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add program module | `modules/home-manager/programs/<name>.nix` | Keep scope narrow; one module per program |
| Wire new module | `modules/home-manager/programs/default.nix` | Missing import means module is dead |
| Shared user files | `modules/home-manager/home.nix` + `modules/home-manager/files/` | Prefer source files under `files/` |
| Shell wrappers | `zsh.nix` + `../files/nushell/functions.nu` | Keep `nb`/`nup` behavior aligned |
| Work-only behavior | `isWork` branches in module files | Do not fork by hostname directly |

## CONVENTIONS
- Use module args (`isDarwin`, `isLinux`, `isWork`) from `lib/default.nix`; avoid `pkgs.stdenv` checks unless needed.
- Keep module boundaries clear:
  - `programs.*` options belong here.
  - Shared asset files belong in `modules/home-manager/files/`.
  - Host-specific package overrides belong in `modules/home-manager/hosts/*`.
- For new `*.nix` module files: add import in `default.nix` in same change.
- Prefer concise, active modules; avoid long commented-out config blocks.

## ANTI-PATTERNS (THIS DIRECTORY)
- Adding a module file but forgetting `default.nix` import (current example: `bottom.nix` exists but not imported).
- Embedding host-specific paths/assumptions in reusable modules unless unavoidable.
- Copying inline shell logic into one shell only; keep zsh and nushell wrappers functionally equivalent.
- Mixing unrelated concerns in one module when a file in `modules/home-manager/files/` should own the payload.

## VALIDATION
```bash
nix flake check
darwin-rebuild build --flake ~/.config/nix-config
```
