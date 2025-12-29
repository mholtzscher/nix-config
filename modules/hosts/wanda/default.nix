{ inputs, ... }:
{
  flake.modules.nixos.wanda =
    { pkgs, config, ... }:
    let
      sshPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwjFs5j8xyYI+p3ckPU0nUYyJ9S2Y753DYUEPRbyGqX"
      ];
      primaryLanInterface = "enp87s0";
      nasPatchInterface = "enp88s0";
      nasLink = {
        address = "10.0.0.10";
        prefixLength = 24;
      };
    in
    {
      imports =
        with inputs.self.modules.nixos;
        [
          system-cli
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
          opencode
          ssh
          dev-tools-packages
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
        hostName = "wanda";
        useNetworkd = true;
        nftables.enable = true;
        defaultGateway = {
          address = "10.69.69.1";
          interface = primaryLanInterface;
        };
        nameservers = [ "10.69.69.1" ];
        interfaces.${primaryLanInterface} = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = "10.69.69.60";
              prefixLength = 24;
            }
          ];
        };
        interfaces.${nasPatchInterface} = {
          useDHCP = false;
          ipv4.addresses = [ nasLink ];
        };
        firewall = {
          enable = true;
          allowedTCPPorts = [
            22
            80
            443
          ];
          allowedUDPPorts = [ 51820 ];
          trustedInterfaces = [ nasPatchInterface ];
        };
      };

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      time.timeZone = "America/Chicago";
      i18n.defaultLocale = "en_US.UTF-8";

      # NixOS state version - do not change
      system.stateVersion = "24.11";
    };
}
