# Work Mac host configuration (dendritic pattern)
# Defines flake.darwinConfigurations using inline configuration
{
  config,
  inputs,
  lib,
  ...
}:
let
  user = "michaelholtzcher";
  hostname = "Michael-Holtzscher-Work";
  isWork = true;
  # Create a limited 'self' object that only contains modules (avoids recursion)
  selfModules = {
    modules = config.flake.modules;
  };
  # Filter inputs to remove 'self' to avoid infinite recursion
  inputsWithoutSelf = lib.filterAttrs (n: _: n != "self") inputs;
in
{
  flake.darwinConfigurations."Michael-Holtzscher-Work" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {
      inputs = inputsWithoutSelf;
      inherit user;
      self = selfModules;
      inherit isWork;
      currentSystemName = hostname;
      currentSystemUser = user;
    };
    modules = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      config.flake.modules.darwin.system
      config.flake.modules.darwin.base
      config.flake.modules.darwin.homebrewCommon
      config.flake.modules.darwin.homebrewWorkMac
      config.flake.modules.darwin.hostWorkMac
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
            isDarwin = true;
            isLinux = false;
            currentSystemName = hostname;
            currentSystemUser = user;
          };
          users.${user} = {
            home = {
              username = user;
              homeDirectory = "/Users/${user}";
              stateVersion = "24.11";
            };
            programs.home-manager.enable = true;
            imports = [
              config.flake.modules.homeManager.profileCommon
              config.flake.modules.homeManager.catppuccinTheme
              config.flake.modules.homeManager.hostWorkMac
              # Work-specific git email override
              {
                programs.git.settings.user.email = lib.mkForce "michaelholtzcher@company.com";
              }
            ];
          };
        };
      }
    ];
  };
}
