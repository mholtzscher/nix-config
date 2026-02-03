# Personal Mac host configuration (dendritic pattern)
# Defines flake.darwinConfigurations using inline configuration
{
  config,
  inputs,
  lib,
  ...
}:
let
  user = "michael";
  hostname = "Michaels-M1-Max";
  isWork = false;
  # Create a limited 'self' object that only contains modules (avoids recursion)
  selfModules = {
    modules = config.flake.modules;
  };
  # Filter inputs to remove 'self' to avoid infinite recursion
  # When nix evaluates inputs.self, it triggers evaluation of the flake outputs
  inputsWithoutSelf = lib.filterAttrs (n: _: n != "self") inputs;
in
{
  flake.darwinConfigurations."Michaels-M1-Max" = inputs.nix-darwin.lib.darwinSystem {
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
      config.flake.modules.darwin.homebrewPersonalMac
      config.flake.modules.darwin.hostPersonalMac
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
              config.flake.modules.homeManager.ollama
              config.flake.modules.homeManager.hostPersonalMac
            ];
          };
        };
      }
    ];
  };
}
