# Wanda - Ubuntu Server Dendritic Host Configuration
# Standalone home-manager for non-NixOS Linux
{
  config,
  lib,
  inputs,
  ...
}:
let
  user = "michael";
  system = "x86_64-linux";
in
{
  flake.homeConfigurations.wanda = inputs.home-manager.lib.homeManagerConfiguration {
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
      # Core CLI tools
      inputs.self.modules.homeManager.bat
      inputs.self.modules.homeManager.eza
      inputs.self.modules.homeManager.fzf
      inputs.self.modules.homeManager.ripgrep
      inputs.self.modules.homeManager.zoxide
      inputs.self.modules.homeManager.fd

      # Development tools
      inputs.self.modules.homeManager.git

      # Catppuccin theming
      inputs.catppuccin.homeModules.catppuccin

      # Legacy bridge
      ../../hosts/ubuntu/wanda.nix
    ];
  };
}
