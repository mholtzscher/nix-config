# nix-darwin system defaults
{ config, lib, ... }:
let
  cfg = config.myFeatures.darwinSystem;
in
{
  options.myFeatures.darwinSystem = {
    enable = lib.mkEnableOption "darwin system defaults" // {
      default = true;
      description = "Common nix-darwin system settings";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.darwin.system =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

        nix.gc.interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };

        fonts.packages = [
          pkgs.nerd-fonts.iosevka
          pkgs.nerd-fonts.jetbrains-mono
        ];

        programs.zsh.enable = true;

        security.pam.services.sudo_local.touchIdAuth = true;

        system.defaults = {
          NSGlobalDomain = {
            AppleKeyboardUIMode = 3;
            AppleInterfaceStyle = "Dark";
            AppleShowAllExtensions = true;
            InitialKeyRepeat = 15;
            KeyRepeat = 2;
          };

          dock = {
            autohide = true;
            tilesize = 48;
            orientation = "left";
            minimize-to-application = true;
            show-process-indicators = true;
            show-recents = false;
            expose-group-apps = true;
            wvous-bl-corner = 1;
            wvous-br-corner = 1;
            wvous-tl-corner = 1;
            wvous-tr-corner = 1;
          };

          finder = {
            AppleShowAllExtensions = true;
            ShowPathbar = true;
            FXEnableExtensionChangeWarning = false;
            FXPreferredViewStyle = "clmv";
          };

          trackpad = {
            Clicking = true;
          };

          screencapture.location = "~/Downloads/ScreenShots";
          loginwindow.GuestEnabled = false;

          CustomUserPreferences = {
            "com.jetbrains.intellij".ApplePressAndHoldEnabled = false;
            "com.jetbrains.intellij.ce".ApplePressAndHoldEnabled = false;

            "com.surteesstudios.Bartender" = {
              UseBartenderBar = 1;
              TriggerSettings = {
                Battery1 = {
                  description = "";
                  icon = {
                    SFSymbolName = "bolt.fill";
                    isTemplate = 1;
                  };
                  isActive = 1;
                  isSpecial = 0;
                  menuBarItemsToActivate."com.apple.controlcenter-Battery" = "Battery";
                  name = "Show Battery when battery condition met";
                  triggerSpecificDict = {
                    "Battery-When" = "OnBatteryPower";
                    "Battery-percentage" = 50;
                  };
                  type = [ "Battery" ];
                };

                TimeMachine1 = {
                  description = "";
                  icon = {
                    SFSymbolName = "bolt.fill";
                    isTemplate = 1;
                  };
                  isActive = 1;
                  isSpecial = 0;
                  menuBarItemsToActivate = {
                    "com.apple.systemuiserver-TimeMachine.TMMenuExtraHost" = "SystemUIServer";
                    "com.apple.systemuiserver-TimeMachineMenuExtra.TMMenuExtraHost" = "Time Machine";
                  };
                  name = "Show Time Machine when time machine is backing up.";
                  triggerSpecificDict.Script = "tmutil status | awk -F'=' '/Running/ {print $2*1}'";
                  type = [ "Script" ];
                };

                WiFi1 = {
                  description = "";
                  icon = {
                    SFSymbolName = "bolt.fill";
                    isTemplate = 1;
                  };
                  isActive = 1;
                  isSpecial = 0;
                  menuBarItemsToActivate."com.apple.controlcenter-WiFi" = "Wi-Fi";
                  name = "Show Wi-Fi when Wi-Fi condition met";
                  triggerSpecificDict.ShowOn = "AllDisconnected";
                  type = [ "WiFi" ];
                };
              };
            };

            "pl.maketheweb.cleanshotx" = {
              afterScreenshotActions = [
                0
                1
                2
              ];
              afterVideoActions = [
                0
                2
              ];
            };
          };
        };

        system.activationScripts.applications.text =
          let
            env = pkgs.buildEnv {
              name = "system-applications";
              paths = config.environment.systemPackages;
              pathsToLink = [ "/Applications" ];
            };
          in
          pkgs.lib.mkForce ''
            # Set up applications.
            echo "setting up /Applications..." >&2
            rm -rf /Applications/Nix\ Apps
            mkdir -p /Applications/Nix\ Apps
            find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read -r src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
          '';
      };
  };
}
