# Wanda - Ubuntu Server Host Configuration
# References dendritic modules but defined separately to avoid recursion
{ inputs, ... }:
let
  user = "michael";
  system = "x86_64-linux";
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs { inherit system; };
  extraSpecialArgs = {
    inherit inputs user;
    self = inputs.self;
    isWork = false;
    isDarwin = false;
    isLinux = true;
    currentSystemName = "wanda";
    currentSystemUser = user;
  };
  modules = [
    inputs.self.modules.homeManager.profileCommon

    # Host-specific config
    inputs.self.modules.homeManager.hostWanda

    # Ubuntu-specific settings
    {
      home.username = user;
      home.homeDirectory = "/home/${user}";
      home.stateVersion = "24.11";
      programs.home-manager.enable = true;
      targets.genericLinux.enable = true;
    }
  ];
}
