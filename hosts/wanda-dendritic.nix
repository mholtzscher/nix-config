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

    # Shell + prompt + env
    inputs.self.modules.homeManager.zsh
    inputs.self.modules.homeManager.starship
    inputs.self.modules.homeManager.direnv
    inputs.self.modules.homeManager.atuin

    # Shells / terminal tooling
    inputs.self.modules.homeManager.nushell
    inputs.self.modules.homeManager.zellij

    # SSH
    inputs.self.modules.homeManager.ssh

    # Development tools - from dendritic modules
    inputs.self.modules.homeManager.git

    # GitHub + JSON + monitoring
    inputs.self.modules.homeManager.gh
    inputs.self.modules.homeManager.gh-dash
    inputs.self.modules.homeManager.jq
    inputs.self.modules.homeManager.btop

    # Tooling
    inputs.self.modules.homeManager.mise
    inputs.self.modules.homeManager.carapace
    inputs.self.modules.homeManager.k9s
    inputs.self.modules.homeManager.lazydocker
    inputs.self.modules.homeManager.lazygit

    # JS runtime
    inputs.self.modules.homeManager.bun

    # Editors
    inputs.self.modules.homeManager.neovim
    inputs.self.modules.homeManager.helix
    inputs.self.modules.homeManager.yazi

    # Languages
    inputs.self.modules.homeManager.go
    inputs.self.modules.homeManager.uv
    inputs.self.modules.homeManager.jujutsu

    # AI tooling
    inputs.self.modules.homeManager.opencode

    # Catppuccin theming
    inputs.catppuccin.homeModules.catppuccin

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
