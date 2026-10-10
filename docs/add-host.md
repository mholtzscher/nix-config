# Add Host

Reference for adding Darwin, NixOS, and standalone home-manager hosts.

## Darwin Host

1. Create `hosts/darwin/<hostname>/default.nix`
2. Create `modules/home-manager/hosts/<hostname>/default.nix`
3. Add host to `flake.nix`

```nix
darwinConfigurations."Host-Name" = lib.mkSystem {
  name = "friendly-name";
  system = "aarch64-darwin";
  darwin = true;
  hostPath = ./hosts/darwin/hostname;
  user = "username";
};
```

- Match the macOS hostname key with the machine hostname
- Put machine-specific user config in `modules/home-manager/hosts/<hostname>/`
- Validate with `nix flake check`

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
- Validate with `nix flake check`

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
- Validate with `nix flake check`

## Placement Rules

- Cross-platform user config: `modules/home-manager/programs/`
- Host-specific user config: `modules/home-manager/hosts/<hostname>/`
- Host-specific NixOS system config: `modules/nixos/hosts/<hostname>/`
- macOS package-manager config: `modules/darwin/homebrew/`
