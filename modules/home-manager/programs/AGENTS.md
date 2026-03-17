# PROGRAM MODULES

## OVERVIEW

Shared home-manager program modules: one file per program, imported through `default.nix`, reused across hosts unless a host override is clearer.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a new shared program | `default.nix` | New module is inactive until imported here |
| Add shell workflow helpers | `zsh.nix` | `nb`, `nup`, `nbt`, `nupt` live here |
| Change OpenCode setup | `opencode.nix` | Wires package, permissions, MCP, shipped config tree |
| Change editor/terminal defaults | `helix.nix`, `neovim.nix`, `ghostty.nix`, `zellij.nix` | Follow existing module shape |
| NixOS-only program wrapper | `webapps.nix` | Keep platform guard inside module |
| Shared aliases only | `../shared-aliases.nix` | Do not bury alias-only changes in unrelated modules |

## STRUCTURE

```text
programs/
|- default.nix         # import registry
|- zsh.nix             # shell helpers + init content
|- opencode.nix        # AI CLI package + config sync
|- ghostty.nix         # example of local platform guards
`- *.nix               # one module per program/tool
```

## CONVENTIONS

- Keep one concern per file: one program, one module.
- Import every new module in `default.nix`; alphabetical order is current style.
- Prefer `isDarwin` / `isLinux` module args over raw `pkgs.stdenv` checks when available.
- Put large file-backed config under `../files/` and map it in, instead of embedding giant strings.
- Keep shared modules host-agnostic; machine-specific packages/settings belong in `modules/home-manager/hosts/*`.

## ANTI-PATTERNS

- Do not add package-only host preferences here when no shared program config exists.
- Do not forget the `default.nix` import when creating a module.
- Do not hardcode work-machine or personal-machine paths unless already gated by `isWork` or host context.
- Do not move NixOS desktop-only behavior here if `modules/nixos/hosts/nixos-desktop/` owns it.
