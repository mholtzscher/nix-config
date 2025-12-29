{ inputs, ... }:
{
  flake.modules.darwin.work-mac =
    { pkgs, config, ... }:
    {
      imports = with inputs.self.modules.darwin; [
        system-desktop
      ];

      # Set constants for work mac
      systemConstants = {
        isWork = true;
        userName = "michaelholtzscher";
        userEmail = "michael.holtzscher@paytient.com";
      };

      # User configuration
      users.users.michaelholtzscher = {
        name = "michaelholtzscher";
        home = "/Users/michaelholtzscher";
      };

      system.primaryUser = "michaelholtzscher";

      # Home-manager for user
      home-manager.users.michaelholtzscher = {
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
        ];

        # Work packages
        home.packages = with pkgs; [
          aerospace
          mkalias
          pokemon-colorscripts-mac
        ];

        # macOS config files
        home.file.".config/raycast/scripts/toggle-aerospace.sh" = {
          source = ../../desktop/aerospace/files/raycast/toggle-aerospace.sh;
          executable = true;
        };
        home.file.".config/raycast/scripts/aerospace-workspace-size.sh" = {
          source = ../../desktop/aerospace/files/raycast/aerospace-workspace-size.sh;
          executable = true;
        };
        home.file.".config/raycast/scripts/aerospace-workspace-size-increment.sh" = {
          source = ../../desktop/aerospace/files/raycast/aerospace-workspace-size-increment.sh;
          executable = true;
        };
        home.file.".config/raycast/scripts/aerospace-workspace-size-decrement.sh" = {
          source = ../../desktop/aerospace/files/raycast/aerospace-workspace-size-decrement.sh;
          executable = true;
        };

        home.activation.aerospaceConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/.config/aerospace"
          run cp -f ${../../desktop/aerospace/files/aerospace.toml} "$HOME/.config/aerospace/aerospace.toml"
          run chmod u+w "$HOME/.config/aerospace/aerospace.toml"
        '';

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
        };
      };

      # nix-homebrew setup
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = "michaelholtzscher";
        autoMigrate = true;
      };

      # Host-specific dock configuration
      system.defaults.dock.persistent-apps = [
        "/Applications/Arc.app"
        "/System/Applications/Messages.app"
        "/Applications/Slack.app"
        "/Applications/Ghostty.app"
        "/Applications/Postico.app"
        "/Applications/IntelliJ IDEA.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/Applications/Todoist.app"
        "/System/Applications/Music.app"
        "/System/Applications/News.app"
        "/Users/michaelholtzscher/Applications/Google Gemini.app"
        "/Users/michaelholtzscher/Applications/Reclaim.app"
      ];
    };
}
