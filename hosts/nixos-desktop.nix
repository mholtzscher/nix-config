# NixOS Desktop - Host Configuration
{ inputs, ... }:
let
  user = "michael";
  system = "x86_64-linux";
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs user;
    self = inputs.self;
    isWork = false;
  };
  modules = [
    # External flake modules
    inputs.home-manager.nixosModules.home-manager
    inputs.catppuccin.nixosModules.catppuccin
    inputs.niri.nixosModules.niri
    inputs.dms.nixosModules.default
    inputs.dms.nixosModules.greeter

    # Host-specific hardware/networking/users
    ./nixos/nixos-desktop/default.nix

    # Dendritic system modules
    inputs.self.modules.nixos.desktopSystem
    inputs.self.modules.nixos.packages # Fonts, 1Password, dev tools
    inputs.self.modules.nixos.gaming # ratbagd for gaming mouse
    inputs.self.modules.nixos.nvidia # NVIDIA GPU drivers
    inputs.self.modules.nixos.steam # Steam, gamemode
    inputs.self.modules.nixos.services # Pipewire, SSH, printing
    inputs.self.modules.nixos.wayland # XDG portals, Niri, DMS
    inputs.self.modules.nixos.greeter # DMS login greeter

    # Home-manager wiring
    inputs.self.modules.nixos.desktopHm
  ];
}
