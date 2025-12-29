{ inputs, ... }:
{
  # System CLI - inherits from system-default, adds CLI tools
  # Used by all hosts (desktop and headless)

  flake.modules.nixos.system-cli =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-default
        security
      ];

      # Common system packages for CLI
      environment.systemPackages = with pkgs; [
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
    imports = with inputs.self.modules.homeManager; [
      system-default
      zsh
      nushell
      starship
      atuin
      carapace
      zoxide
      git
      delta
      gh
      gh-dash
      lazygit
      jujutsu
      bat
      eza
      fd
      fzf
      ripgrep
      jq
      yazi
      btop
      bottom
      helix
      zellij
      go
      mise
      uv
      poetry
      pyenv
      k9s
      lazydocker
      opencode
      ssh
      dev-tools-packages
    ];
  };
}
