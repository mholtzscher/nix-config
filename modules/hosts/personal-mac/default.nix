{ inputs, ... }:
{
  flake.modules.darwin.personal-mac =
    { pkgs, config, ... }:
    {
      imports = with inputs.self.modules.darwin; [
        system-desktop
      ];

      # Set constants for personal mac
      systemConstants = {
        isWork = false;
        userName = "michael";
        userEmail = "michael@holtzscher.com";
      };

      # User configuration
      users.users.michael = {
        name = "michael";
        home = "/Users/michael";
      };

      system.primaryUser = "michael";

      # Home-manager for user
      home-manager.users.michael = {
        imports = with inputs.self.modules.homeManager; [
          system-desktop
        ];

        # Personal packages
        home.packages = with pkgs; [
          code-cursor
          discord
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
          OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
        };
      };

      # nix-homebrew setup
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = "michael";
        autoMigrate = true;
      };

      # Host-specific dock configuration
      system.defaults.dock.persistent-apps = [
        "/Applications/Arc.app"
        "/Applications/Obsidian.app"
        "/System/Applications/Messages.app"
        "/Applications/WhatsApp.app"
        "${pkgs.discord}/Applications/Discord.app"
        "/Applications/1Password.app"
        "/Applications/Ghostty.app"
        "/Applications/IntelliJ IDEA CE.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/Applications/Todoist.app"
        "/System/Applications/Music.app"
        "/System/Applications/News.app"
      ];
    };
}
