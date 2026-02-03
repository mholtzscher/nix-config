# NixOS DMS Greeter module
# DankMaterialShell login greeter configuration
{ config, lib, ... }:
let
  cfg = config.myFeatures.nixosGreeter;
in
{
  options.myFeatures.nixosGreeter = {
    enable = lib.mkEnableOption "NixOS DMS greeter" // {
      default = true;
      description = "DankMaterialShell login greeter configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.nixos.greeter = {
      # DMS (Dank Material Shell) greeter via greetd
      # Runs the login screen under Niri with an explicit greeter-time config.
      programs.dank-material-shell.greeter = {
        enable = true;

        compositor = {
          name = "niri";

          # This runs before the user session (no home-manager), so keep outputs deterministic.
          customConfig = ''
            hotkey-overlay {
              skip-at-startup
            }

            environment {
              DMS_RUN_GREETER "1"
            }

            gestures {
              hot-corners {
                off
              }
            }

            output "DP-1" {
              mode "5120x1440@120"
              scale 1
              position x=0 y=0
            }

            layout {
              background-color "#000000"
            }
          '';
        };

        # Copy the user's DMS config into /var/lib/dms-greeter for theme/wallpaper sync.
        configHome = "/home/michael";

        logs = {
          save = false;
          path = "/var/log/dms-greeter.log";
        };
      };
    };
  };
}
