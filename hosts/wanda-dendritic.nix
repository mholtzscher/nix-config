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
    # Core CLI tools - from dendritic modules
    inputs.self.modules.homeManager.bat
    inputs.self.modules.homeManager.eza
    inputs.self.modules.homeManager.fzf
    inputs.self.modules.homeManager.ripgrep
    inputs.self.modules.homeManager.zoxide
    inputs.self.modules.homeManager.fd

    # Development tools - from dendritic modules
    inputs.self.modules.homeManager.git

    # Catppuccin theming
    inputs.catppuccin.homeModules.catppuccin

    # Ubuntu-specific settings
    {
      home.username = user;
      home.homeDirectory = "/home/${user}";
      targets.genericLinux.enable = true;
    }
  ];
}
