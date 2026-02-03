# NixOS Desktop - Host Configuration
# References dendritic modules but defined separately to avoid recursion
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
    # Import home-manager NixOS module
    inputs.home-manager.nixosModules.home-manager

    # Import catppuccin
    inputs.catppuccin.nixosModules.catppuccin

    # Import Niri
    inputs.niri.nixosModules.niri

    # Import DMS
    inputs.dms.nixosModules.default
    inputs.dms.nixosModules.greeter

    # Legacy NixOS system config (hardware, services, users, etc.)
    ./nixos/nixos-desktop/default.nix

    # Dendritic system modules
    inputs.self.modules.nixos.desktopSystem
    inputs.self.modules.nixos.desktopHm
  ];
}
