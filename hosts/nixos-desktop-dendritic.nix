# NixOS Desktop - Host Configuration
# References dendritic modules but defined separately to avoid recursion
{ inputs, ... }:
let
  user = "michael";
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
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

    # Compatibility: legacy host sets user shell = zsh
    { programs.zsh.enable = true; }

    # Required by legacy config (NVIDIA, etc.)
    { nixpkgs.config.allowUnfree = true; }

    # Home-manager configuration
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inherit inputs user;
          self = inputs.self;
          isWork = false;
          isDarwin = false;
          isLinux = true;
          currentSystemName = "nixos-desktop";
          currentSystemUser = user;
        };
        users.${user} = lib.mkForce {
          home.stateVersion = "24.11";
          programs.home-manager.enable = true;
          imports = [
            inputs.self.modules.homeManager.profileCommon

            # Host-specific config
            inputs.self.modules.homeManager.hostNixosDesktop

            # Linux desktop extras
            inputs.self.modules.homeManager.firefox
            inputs.self.modules.homeManager.zen
            inputs.self.modules.homeManager.webapps
          ];
        };
      };
    }

  ];
}
