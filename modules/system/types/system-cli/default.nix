{ inputs, ... }:
{
  # System CLI - inherits from system-default, adds CLI tools
  # Used by all hosts (desktop and headless)

  flake.modules.nixos.system-cli = {
    imports = with inputs.self.modules.nixos; [
      system-default
      security
    ];

    # Common system packages for CLI
    environment.systemPackages = with inputs.nixpkgs.legacyPackages.x86_64-linux; [
      curl
      tree
      unzip
      lshw
      pciutils
      usbutils
    ];

    # Console configuration
    console = {
      font = "Lat2-Terminus16";
      keyMap = inputs.nixpkgs.lib.mkDefault "us";
    };

    # Documentation settings
    documentation = {
      enable = true;
      man.enable = true;
      dev.enable = false;
    };

    # Nix download buffer for performance
    nix.settings.download-buffer-size = 512 * 1024 * 1024;
  };

  flake.modules.darwin.system-cli = {
    imports = with inputs.self.modules.darwin; [
      system-default
    ];
  };

  # Home-manager CLI - imports all CLI programs directly
  flake.modules.homeManager.system-cli = {
    imports = [
      ../../system/types/system-default/homeManager.nix
      ../../programs/shell/zsh.nix
      ../../programs/shell/nushell.nix
      ../../programs/shell/starship.nix
      ../../programs/shell/atuin.nix
      ../../programs/shell/carapace.nix
      ../../programs/shell/zoxide.nix
      ../../programs/git/git.nix
      ../../programs/git/delta.nix
      ../../programs/git/gh.nix
      ../../programs/git/gh-dash.nix
      ../../programs/git/lazygit.nix
      ../../programs/git/jujutsu.nix
      ../../programs/cli-tools/bat.nix
      ../../programs/cli-tools/eza.nix
      ../../programs/cli-tools/fd.nix
      ../../programs/cli-tools/fzf.nix
      ../../programs/cli-tools/ripgrep.nix
      ../../programs/cli-tools/jq.nix
      ../../programs/cli-tools/yazi.nix
      ../../programs/cli-tools/btop.nix
      ../../programs/cli-tools/bottom.nix
      ../../programs/editor/helix.nix
      ../../programs/editor/zed.nix
      ../../programs/terminal/ghostty.nix
      ../../programs/terminal/zellij.nix
      ../../programs/dev-tools/go.nix
      ../../programs/dev-tools/mise.nix
      ../../programs/dev-tools/uv.nix
      ../../programs/dev-tools/poetry.nix
      ../../programs/dev-tools/pyenv.nix
      ../../programs/devops/k9s.nix
      ../../programs/devops/lazydocker.nix
      ../../programs/browser/firefox.nix
      ../../programs/ai-tools/opencode.nix
      ../../programs/ssh/ssh-config.nix
      ../../programs/dev-tools/default.nix # for dev-tools-packages
    ];
  };
}
