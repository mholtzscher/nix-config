# NixOS Desktop host configuration (dendritic pattern)
# Defines flake.nixosConfigurations using inline configuration
{
  config,
  inputs,
  lib,
  ...
}:
let
  user = "michael";
  hostname = "nixos-desktop";
  isWork = false;
  # Create a limited 'self' object that only contains modules (avoids recursion)
  selfModules = {
    modules = config.flake.modules;
  };
  # Filter inputs to remove 'self' to avoid infinite recursion
  inputsWithoutSelf = lib.filterAttrs (n: _: n != "self") inputs;
in
{
  flake.nixosConfigurations.nixos-desktop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inputs = inputsWithoutSelf;
      inherit user;
      self = selfModules;
      inherit isWork;
      currentSystemName = hostname;
      currentSystemUser = user;
    };
    modules = [
      inputs.home-manager.nixosModules.home-manager
      # External flake modules
      inputs.catppuccin.nixosModules.catppuccin
      inputs.niri.nixosModules.niri
      inputs.dms.nixosModules.default
      inputs.dms.nixosModules.greeter
      # Hardware and base system config
      ../../hosts/nixos/nixos-desktop
      # Dendritic system modules
      config.flake.modules.nixos.desktopSystem
      config.flake.modules.nixos.packages
      config.flake.modules.nixos.gaming
      config.flake.modules.nixos.nvidia
      config.flake.modules.nixos.steam
      config.flake.modules.nixos.services
      config.flake.modules.nixos.wayland
      config.flake.modules.nixos.greeter
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inputs = inputsWithoutSelf;
            inherit user;
            self = selfModules;
            inherit isWork;
            isDarwin = false;
            isLinux = true;
            currentSystemName = hostname;
            currentSystemUser = user;
          };
          users.${user} = {
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
            imports = [
              # Common profile (CLI tools, shell, etc.)
              config.flake.modules.homeManager.profileCommon
              config.flake.modules.homeManager.catppuccinTheme
              config.flake.modules.homeManager.ollama
              # Host-specific user config
              config.flake.modules.homeManager.hostNixosDesktop
              # Browsers
              config.flake.modules.homeManager.firefox
              config.flake.modules.homeManager.zen
              config.flake.modules.homeManager.webapps
              # Desktop environment
              config.flake.modules.homeManager.nixosComposition
              config.flake.modules.homeManager.nixosGaming
              config.flake.modules.homeManager.nixosWallpaper
            ];
          };
        };
      }
    ];
  };
}
