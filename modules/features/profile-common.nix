# Common Home Manager profile (bundles many feature modules)
{ config, lib, ... }:
let
  cfg = config.myFeatures.profileCommon;
in
{
  options.myFeatures.profileCommon = {
    enable = lib.mkEnableOption "common home-manager profile" // {
      default = true;
      description = "Bundle of common home-manager modules";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.profileCommon =
      { self, ... }:
      {
        imports = [
          self.modules.homeManager.base
          self.modules.homeManager.packages
          self.modules.homeManager.aliases

          # Core CLI
          self.modules.homeManager.bat
          self.modules.homeManager.eza
          self.modules.homeManager.fzf
          self.modules.homeManager.ripgrep
          self.modules.homeManager.zoxide
          self.modules.homeManager.fd

          # Shell + prompt + env
          self.modules.homeManager.zsh
          self.modules.homeManager.starship
          self.modules.homeManager.direnv
          self.modules.homeManager.atuin
          self.modules.homeManager.nushell

          # Terminal tooling
          self.modules.homeManager.zellij
          self.modules.homeManager.ghostty

          # SSH
          self.modules.homeManager.ssh

          # Git + GitHub
          self.modules.homeManager.git
          self.modules.homeManager.gh
          self.modules.homeManager.gh-dash

          # Data / monitoring
          self.modules.homeManager.jq
          self.modules.homeManager.btop
          self.modules.homeManager.bottom

          # Tooling
          self.modules.homeManager.mise
          self.modules.homeManager.carapace
          self.modules.homeManager.k9s
          self.modules.homeManager.lazydocker
          self.modules.homeManager.lazygit

          # Editors
          self.modules.homeManager.neovim
          self.modules.homeManager.helix
          self.modules.homeManager.yazi

          # Languages
          self.modules.homeManager.bun
          self.modules.homeManager.go
          self.modules.homeManager.uv
          self.modules.homeManager.jujutsu

          # AI tooling
          self.modules.homeManager.opencode
          self.modules.homeManager.ollama
        ];
      };
  };
}
