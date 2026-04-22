# AGENTS.md

Guidance for this multi-platform Nix flake repo.

**Last updated:** 2026-04-22  
**Repository:** nix-config (personal NixOS/Darwin/home-manager configurations)

## Safety

- Never apply Nix changes directly.
- Allowed validation: `nh darwin build`, `nh os build`, `nh home build`
- `nix flake update` — only run when user explicitly requests it
- Forbidden: `nh darwin switch`, `nh os switch`, `nh home switch`, `darwin-rebuild switch`, `nixos-rebuild switch`, `home-manager switch`, `nup`, or any other apply command. The user runs these manually outside the agent.

## Nix Commands

Prefer `nh` over raw `darwin-rebuild`, `nixos-rebuild`, `home-manager` commands. It auto-detects the flake ref and provides better output.

| Platform | Validate (allowed) | Apply (forbidden) |
|---|---|---|
| Darwin | `nh darwin build .#<hostname>` | `nh darwin switch .#<hostname>` |
| NixOS | `nh os build .#<hostname>` | `nh os switch .#<hostname>` |
| Home Manager | `nh home build .#<user>@<hostname>` | `nh home switch .#<user>@<hostname>` |

## Workflow

1. Make minimal changes.
2. Validate with `nh` build (dry-run, doesn't activate) — see table above.
3. Report failures clearly.
4. User runs apply commands.

### Example workflow

```
User: "Add ripgrep to my packages"
Agent: Edit modules/home-manager/packages.nix to add ripgrep
Agent: Run: nh darwin build .#michaels-macbook
Agent: Report: "Build successful. Run 'nh darwin switch .#michaels-macbook' to apply."
User: Runs switch command manually
```

## Repo Map

- `flake.nix`: host definitions
- `lib/default.nix`: shared builders like `mkSystem` and `mkHome`
- `hosts/`: per-host entrypoints
- `modules/darwin/`: macOS system config
- `modules/nixos/`: NixOS system config
- `modules/shared/`: shared system config
- `modules/home-manager/`: user config
- `modules/*/hosts/{hostname}/`: host-specific overrides

## Routing Rules

- Add cross-platform programs in `modules/home-manager/programs/`
- Add shared packages in `modules/home-manager/packages.nix`
- Add macOS package-manager config in `modules/darwin/homebrew/`
- Add host-specific user config in `modules/home-manager/hosts/{hostname}/`
- Add host-specific NixOS system config in `modules/nixos/hosts/{hostname}/`
- Use platform guards like `lib.mkIf isDarwin` for OS-specific behavior
- Use host modules for machine-specific behavior

## Key Concepts

- `mkSystem` builds Darwin and NixOS hosts
- `mkHome` builds standalone Home Manager configs for non-NixOS Linux
- Common module args include `currentSystemName`, `currentSystemUser`, `isDarwin`, `isLinux`, and `inputs`
- NixOS modules also receive `currentSystem`, `graphical`, and `gaming`

## Host Types

- Darwin hosts live under `hosts/darwin/`
- NixOS hosts live under `hosts/nixos/`
- Non-NixOS Linux hosts live under `hosts/ubuntu/` and use standalone Home Manager

## Host Discovery

To find available hosts for build commands:

```bash
# Darwin hosts
ls hosts/darwin/

# NixOS hosts
ls hosts/nixos/

# Standalone home-manager hosts (Ubuntu/non-NixOS)
ls hosts/ubuntu/
```

## Troubleshooting

### Reporting build failures

Include in error reports:
- Full command that was run
- Complete error output (last 20-30 lines if verbose)
- Host being built (e.g., `.#michaels-macbook`)
- Recent changes made

### Common `nh` errors

| Error | Likely cause | Resolution |
|-------|------------|------------|
| `error: cannot find flake` | Wrong directory or flake.nix missing | Ensure you're in repo root |
| `error: attribute '<host>' missing` | Host name typo or doesn't exist | Check `ls hosts/<platform>/` |
| `build failed` | Syntax error in .nix files | Check line numbers in error |

## Reference Docs

- `docs/layout.md`: repo structure, host inventory, module flow
- `docs/add-host.md`: Darwin, NixOS, and standalone home-manager host templates
- `docs/common-tasks.md`: common edit locations for programs, packages, and system settings
- `docs/platform-guidelines.md`: platform guards, host-vs-platform rules, module arg patterns
