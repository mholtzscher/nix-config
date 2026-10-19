# Add Host

Reference for adding NixOS and standalone Linux Home Manager hosts.

Macs are managed through Mise in `mholtzscher/workstation`; do not add Darwin targets here.

## NixOS Host

1. Create `hosts/nixos/<hostname>/default.nix`
2. Create `modules/home-manager/hosts/<hostname>/default.nix`
3. Create `modules/nixos/hosts/<hostname>/` if the machine needs system-specific modules
4. Add host to `flake.nix`

```nix
nixosConfigurations.hostname = lib.mkSystem {
  name = "friendly-name";
  system = "x86_64-linux";
  hostPath = ./hosts/nixos/hostname;
  user = "username";
  graphical = true;
  gaming = false;
};
```

5. Generate hardware config:

```bash
nixos-generate-config --root /mnt --show-hardware-config > hosts/nixos/hostname/hardware-configuration.nix
```

- `graphical = true` enables graphical host modules and UI-related inputs
- `graphical = false` keeps the host headless
- `gaming = true` exposes the flag to modules; modules opt in explicitly
- Validate per `docs/NIX_WORKFLOW.md`

## Standalone Home-Manager Host

Use this for non-NixOS Linux hosts.

1. Create `hosts/ubuntu/<hostname>/default.nix`
2. Create `modules/home-manager/hosts/<hostname>/default.nix`
3. Add host to `flake.nix`

```nix
homeConfigurations.hostname = lib.mkHome {
  name = "hostname";
  system = "x86_64-linux";
  hostPath = ./hosts/ubuntu/hostname;
  user = "username";
};
```

Minimal host file:

```nix
{ ... }:
{
  imports = [
    ../../../modules/home-manager/home.nix
    ../../../modules/home-manager/hosts/hostname
  ];

  home = {
    username = "username";
    homeDirectory = "/home/username";
  };

  targets.genericLinux.enable = true;
}
```

Activation on target machine:

```bash
nix run home-manager -- switch --flake .#hostname
home-manager switch --flake .#hostname
```

- Disable GUI-only programs in host config if the machine is headless
- Validate per `docs/NIX_WORKFLOW.md`

## Placement Rules

- Shared Linux user config: `modules/home-manager/programs/`
- Host-specific user config: `modules/home-manager/hosts/<hostname>/`
- Host-specific NixOS system config: `modules/nixos/hosts/<hostname>/`
- Mac apps/fonts: Mise `[bootstrap.packages]`, outside this Nix repository
