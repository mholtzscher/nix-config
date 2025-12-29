{ inputs, ... }:
{
  # NixOS Desktop host

  flake.modules.nixos.nixos-desktop =
    { pkgs, config, ... }:
    let
      sshPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwjFs5j8xyYI+p3ckPU0nUYyJ9S2Y753DYUEPRbyGqX"
      ];
    in
    {
      imports =
        with inputs.self.modules.nixos;
        [
          system-desktop
          gaming
        ]
        ++ [ ./_hardware.nix ];

      users.users.michael = {
        isNormalUser = true;
        home = "/home/michael";
        description = "Michael Holtzscher";
        extraGroups = [
          "wheel"
          "networkmanager"
          "docker"
        ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = sshPublicKeys;
      };

      home-manager.users.michael = {
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
          zed
          ghostty
          zellij
          go
          mise
          uv
          poetry
          pyenv
          k9s
          lazydocker
          firefox
          opencode
          ssh
          dev-tools-packages
          niri
          vicinae
          wallpaper
          webapps
          gaming
        ];

        # NixOS desktop packages
        home.packages = with pkgs; [
          discord
          vesktop
        ];

        home.file.".config/kafkactl/config.yml".source = ../../programs/devops/files/kafkactl.yaml;
        home.file.".ideavimrc".source = ../../programs/editor/files/ideavimrc;
        home.file.".config/topiary/languages.ncl".text =
          builtins.replaceStrings [ "TREE_SITTER_NU_PATH" ] [ "${pkgs.tree-sitter-grammars.tree-sitter-nu}" ]
            (builtins.readFile ../../programs/dev-tools/files/topiary/languages.ncl);
        home.file.".config/topiary/languages/nu.scm".source = "${inputs.topiaryNushell}/languages/nu.scm";
        home.file.".config/1Password/ssh/agent.toml".source = ../../programs/ssh/files/1password-agent.toml;

        home.sessionVariables = {
          COMPOSE_PROFILES = "default";
          TOPIARY_CONFIG_FILE = "$HOME/.config/topiary/languages.ncl";
          TOPIARY_LANGUAGE_DIR = "$HOME/.config/topiary/languages";
          OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
        };
      };

      networking = {
        hostName = "nixos-desktop";
        networkmanager.enable = true;
        firewall = {
          enable = true;
          extraCommands = ''
            iptables -A nixos-fw -p tcp --dport 22 -s 10.69.69.0/24 -j nixos-fw-accept
          '';
        };
      };

      systemd.tmpfiles.rules = [
        "d /home/michael/games 0755 michael users -"
      ];

      hardware.logitech.wireless = {
        enable = true;
        enableGraphical = true;
      };

      time.timeZone = "America/Chicago";
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
      };

      # NixOS state version - do not change
      system.stateVersion = "24.11";
    };
}
