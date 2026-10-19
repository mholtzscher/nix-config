# Linux Nix Configuration

NixOS and standalone Linux Home Manager configurations. The personal and work
Macs have moved entirely to [mholtzscher/workstation](https://github.com/mholtzscher/workstation)
with Mise; they do not require Nix or nix-darwin.

## Managed Hosts

| Host | Configuration | Role |
| --- | --- | --- |
| `nixos-desktop` | `nixosConfigurations.nixos-desktop` | Niri/Noctalia desktop, development, gaming, and NVIDIA support |
| `wanda` | `homeConfigurations.wanda` | Standalone Home Manager on Ubuntu |

`homeConfigurations."michael@wanda"` aliases Wanda for `nh` auto-detection.

## Ownership

- **NixOS** manages the desktop's OS, services, compositor, gaming integration, and hardware settings.
- **Home Manager** manages Linux-specific user integration and remaining Nix packages.
- **Mise/workstation** manages development runtimes, most CLIs, editor configuration,
  shell startup files, agent tools, and other writable dotfiles across machines.
- **Macs** use Mise for apps, fonts, preferences, and native security policy. There
  are no Mac hosts, Darwin builders, or nix-darwin inputs in this flake.

Mise installs `brew:` and `brew-cask:` packages directly, without requiring the
Homebrew CLI. The `/opt/homebrew` prefix still holds packages and must not be deleted.

## Prerequisites

- Nix with `nix-command` and `flakes` enabled on Linux; NixOS includes Nix.
- Git for the repository.
- Home Manager is provided by the flake input.

## Structure

```text
flake.nix                         # Inputs and Linux host declarations
lib/default.nix                   # mkSystem (NixOS) and mkHome (standalone Linux)
hosts/
  nixos/nixos-desktop/             # System entrypoint, hardware, users
  ubuntu/wanda/                   # Standalone Home Manager entrypoint
modules/
  shared/                         # Nix settings and shared system modules
  nixos/                          # Core NixOS configuration
    hosts/nixos-desktop/           # Desktop composition, gaming, packages
  home-manager/
    home.nix                      # Shared Linux user configuration
    packages.nix                  # Remaining Nix-managed user packages
    programs/                     # Reusable Linux user modules
    hosts/                        # Desktop and Wanda user settings
    files/                        # Linux-managed assets
pkgs/                             # Custom packages
scripts/                          # Validation, updates, and utilities
docs/                             # Layout, editing, and validation references
```

## Validate

Follow [docs/NIX_WORKFLOW.md](docs/NIX_WORKFLOW.md):

```sh
./scripts/agent-validate.sh
```

The script formats all Nix files, then builds the local NixOS system or the
selected standalone Home Manager configuration. To explicitly select Wanda
on a non-NixOS Linux machine:

```sh
./scripts/agent-validate.sh wanda
```

On macOS the script exits before formatting or calling Nix. Validate this
repository on Linux instead.

## Apply — User Only

After validation, the user may apply on the relevant Linux host:

```sh
# NixOS desktop
nh os switch

# Wanda, from this checkout
nh home switch '.#michael@wanda'
```

The Mise-managed `nb` and `nup` helpers select NixOS or standalone Home Manager
on Linux. Nix maintenance commands and status hooks are not loaded on Macs.

Agents never apply Nix changes. `nix flake update` runs only when explicitly requested.

## Mac Workstations

Mac configuration lives in the writable Mise files, not this checkout:

```sh
mise dot sync
mise dot pull
mise run macos:security -- --check
```

The shared configuration and personal/work profiles select apps and tools.
`macos:security` maintains native Touch ID sudo with session reattachment and
disabled guest login. Its `--check` mode verifies without applying policy changes.

## Editing and Adding Hosts

- [docs/common-tasks.md](docs/common-tasks.md): packages, programs, managed files, and custom package updaters.
- [docs/add-host.md](docs/add-host.md): NixOS and standalone Linux host setup.
- [docs/layout.md](docs/layout.md): module flow and builder arguments.
- [docs/platform-guidelines.md](docs/platform-guidelines.md): host boundaries and compatibility platform flags.
- [docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md): implementation conventions.
- [docs/SECRETS_WORKFLOW.md](docs/SECRETS_WORKFLOW.md): secret management through `./scripts/secrets`; never inline plaintext secrets.
- [AGENTS.md](AGENTS.md): repository safety and required reading.

Existing modules retain `isDarwin = false` and `isLinux = true` for compatibility.
Use host modules and capability flags for new Linux-specific behavior.

## Flake Inputs

- `nixpkgs`, `nixpkgs-master`: Linux packages.
- `home-manager`: Linux user environments.
- `catppuccin`: system and user theming.
- `melt`: the Linux CLI package.
- `noctalia`, `noctalia-greeter`: desktop shell and greeter.
- `helium`: browser packaging.

Historical migration specs and [the restoration reference](docs/nix-restoration.md)
are retained for history. Their retired Mac paths are not current configuration.

## License and Contributing

Personal configuration; use it as reference or inspiration for your own setup.
