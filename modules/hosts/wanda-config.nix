# Wanda host configuration (dendritic pattern)
# Standalone home-manager for Ubuntu server
# Defines flake.homeConfigurations using inline configuration
{
  config,
  inputs,
  lib,
  ...
}:
let
  user = "michael";
  hostname = "wanda";
  isWork = false;
  system = "x86_64-linux";
  # Create a limited 'self' object that only contains modules (avoids recursion)
  selfModules = {
    modules = config.flake.modules;
  };
  # Filter inputs to remove 'self' to avoid infinite recursion
  inputsWithoutSelf = lib.filterAttrs (n: _: n != "self") inputs;
in
{
  flake.homeConfigurations.wanda = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { inherit system; };
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
    modules = [
      config.flake.modules.homeManager.profileCommon
      config.flake.modules.homeManager.hostWanda
      {
        home = {
          username = user;
          homeDirectory = "/home/${user}";
          stateVersion = "24.11";
        };
        programs.home-manager.enable = true;
        targets.genericLinux.enable = true;
      }
    ];
  };
}
