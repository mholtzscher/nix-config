# Common Home Manager profile (bundles many feature modules)
# This is an "Inheritance Aspect" that collects all common HM modules
{
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
        self.modules.homeManager.delta

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
        # Note: ollama is added per-host (excluded from work machines)
      ];
    };
}
