{ pkgs, lib, ... }:
{
  # Aerospace is macOS-only - wrap entire config in platform check
  config = lib.mkIf pkgs.stdenv.isDarwin {
    programs.aerospace = {
      enable = false;

      userSettings = {
        # Startup commands - Commands that run after AeroSpace starts
        after-startup-command = [
          "exec-and-forget borders inactive_color=0xFF5D3EA8 active_color=0xFF9E8BCC width=5.0 hidpi=on style=round"
        ];

        # Monitor focus - Callback when focused monitor changes
        # Mouse lazily follows focused monitor center (default i3-like behavior)
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

        # Gaps between windows (inner-*) and between monitor edges (outer-*)
        gaps = {
          inner.horizontal = 20;
          inner.vertical = 20;
          outer.right = [
            { monitor."DeskPad Display" = 0; }
            { monitor."built-in" = 10; }
            { monitor.main = 300; }
            24
          ];
          outer.left = [
            { monitor."DeskPad Display" = 0; }
            { monitor."built-in" = 10; }
            { monitor.main = 300; }
            24
          ];
          outer.bottom = 10;
          outer.top = 10;
        };

        # Key bindings - Main binding mode
        mode.main.binding = {
          # Navigation
          "alt-ctrl-cmd-h" = "focus left";
          "alt-ctrl-cmd-j" = "focus down";
          "alt-ctrl-cmd-k" = "focus up";
          "alt-ctrl-cmd-l" = "focus right";

          # Layout and window management
          "alt-ctrl-cmd-minus" = "layout floating tiling";
          "alt-ctrl-cmd-o" = "fullscreen --no-outer-gaps";

          # Window resizing
          "alt-ctrl-cmd-period" = "resize width -100";
          "alt-ctrl-cmd-comma" = "resize width +100";
          "alt-ctrl-cmd-u" = "resize width 2400";

          # Workspace switching
          "alt-ctrl-cmd-a" = "workspace Arc";
          "alt-ctrl-cmd-s" = "workspace Slack";
          "alt-ctrl-cmd-g" = "workspace Ghostty";
          "alt-ctrl-cmd-m" = "workspace Messaging";
          "alt-ctrl-cmd-i" = "workspace IntelliJ";
          "alt-ctrl-cmd-v" = "workspace VSCode";
          "alt-ctrl-cmd-p" = "workspace Postico";
          "alt-ctrl-cmd-d" = "workspace Deskpad";
          "alt-ctrl-cmd-r" = "workspace Reclaim";
          "alt-ctrl-cmd-t" = "workspace Tools";
          "alt-ctrl-cmd-e" = "workspace EverythingElse";

          # Move windows to workspaces
          "alt-shift-cmd-ctrl-a" = "move-node-to-workspace Arc";
          "alt-shift-cmd-ctrl-s" = "move-node-to-workspace Slack";
          "alt-shift-cmd-ctrl-g" = "move-node-to-workspace Ghostty";
          "alt-shift-cmd-ctrl-m" = "move-node-to-workspace Messaging";
          "alt-shift-cmd-ctrl-i" = "move-node-to-workspace IntelliJ";
          "alt-shift-cmd-ctrl-v" = "move-node-to-workspace VSCode";
          "alt-shift-cmd-ctrl-p" = "move-node-to-workspace Postico";
          "alt-shift-cmd-ctrl-d" = "move-node-to-workspace Deskpad";
          "alt-shift-cmd-ctrl-r" = "move-node-to-workspace Reclaim";
          "alt-shift-cmd-ctrl-t" = "move-node-to-workspace Tools";
          "alt-shift-cmd-ctrl-e" = "move-node-to-workspace EverythingElse";

          # Workspace navigation
          "alt-tab" = "workspace-back-and-forth";
          "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";

          # Service mode
          "alt-shift-semicolon" = "mode service";
        };

        # Service binding mode - For advanced operations
        mode.service.binding = {
          "esc" = [
            "reload-config"
            "mode main"
          ];
          "r" = [
            "flatten-workspace-tree"
            "mode main"
          ]; # Reset layout
          "f" = [
            "layout floating tiling"
            "mode main"
          ]; # Toggle floating/tiling
          "backspace" = [
            "close-all-windows-but-current"
            "mode main"
          ];

          # Join windows
          "alt-shift-h" = [
            "join-with left"
            "mode main"
          ];
          "alt-shift-j" = [
            "join-with down"
            "mode main"
          ];
          "alt-shift-k" = [
            "join-with up"
            "mode main"
          ];
          "alt-shift-l" = [
            "join-with right"
            "mode main"
          ];
        };

        # Workspace to monitor assignment - Force workspaces to appear on specific monitors
        # Monitor patterns: 'main', 'secondary', numbers (1-based), or regex patterns
        workspace-to-monitor-force-assignment = {
          Arc = [
            "main"
            "built-in"
          ];
          Slack = [
            "main"
            "built-in"
          ];
          Ghostty = [
            "DeskPad Display"
            "main"
            "built-in"
          ];
          Messaging = [
            "main"
            "built-in"
          ];
          IntelliJ = [
            "DeskPad Display"
            "main"
            "built-in"
          ];
          VSCode = [
            "DeskPad Display"
            "main"
            "built-in"
          ];
          Postico = [
            "DeskPad Display"
            "main"
            "built-in"
          ];
          Deskpad = [
            "main"
            "built-in"
          ];
          Reclaim = [
            "main"
            "built-in"
          ];
          Tools = [
            "main"
            "built-in"
          ];
          EverythingElse = [
            "main"
            "built-in"
          ];
        };

        # Window detection rules - Run commands when new windows are detected
        # Conditions: app-id, app-name-regex-substring, window-title-regex-substring, workspace, during-aerospace-startup
        on-window-detected = [
          {
            "if" = {
              app-name-regex-substring = "Arc";
            };
            run = [ "move-node-to-workspace Arc" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Zen";
            };
            run = [ "move-node-to-workspace Arc" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Slack";
            };
            run = [ "move-node-to-workspace Slack" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Ghostty";
            };
            run = [ "move-node-to-workspace Ghostty" ];
          }
          {
            "if" = {
              app-name-regex-substring = "WhatsApp";
            };
            run = [ "move-node-to-workspace Messaging" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Messages";
            };
            run = [ "move-node-to-workspace Messaging" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Intellij";
            };
            run = [ "move-node-to-workspace IntelliJ" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Code";
            };
            run = [ "move-node-to-workspace VSCode" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Todoist";
            };
            run = [ "move-node-to-workspace Tools" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Reclaim";
            };
            run = [ "move-node-to-workspace Reclaim" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Postico";
            };
            run = [ "move-node-to-workspace Postico" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Deskpad";
            };
            run = [
              "layout tiling" # Force tiling for Deskpad app
              "move-node-to-workspace Deskpad"
            ];
          }
          {
            "if" = {
              app-name-regex-substring = "Google Gemini";
            };
            run = [ "move-node-to-workspace Tools" ];
          }
          {
            "if" = {
              app-id = "com.1password.1password";
            };
            run = [ "layout floating" ]; # Force 1Password to float (password manager should be accessible)
          }
          {
            "if" = {
              app-name-regex-substring = "Gmail";
            };
            run = [ "move-node-to-workspace Reclaim" ];
          }
          {
            "if" = {
              app-name-regex-substring = "Music";
            };
            run = [ "move-node-to-workspace Tools" ];
          }
          {
            "if" = {
              app-name-regex-substring = "MOTIV Mix";
            };
            run = [ "move-node-to-workspace EverythingElse" ];
          }
          {
            "if" = {
              app-name-regex-substring = "CatoClient";
            };
            run = [ "move-node-to-workspace EverythingElse" ];
          }
        ];
      };
    };
  };
}
