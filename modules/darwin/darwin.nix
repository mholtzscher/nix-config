{ pkgs, config, ... }:
{
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Darwin-specific nix settings
  # Garbage collection schedule for macOS (runs weekly on Sundays at 2:00 AM)
  nix.gc.interval = {
    Weekday = 0; # Sunday
    Hour = 2;
    Minute = 0;
  };

  fonts.packages = [
    pkgs.nerd-fonts.iosevka
    pkgs.nerd-fonts.go-mono
    pkgs.nerd-fonts.terminess-ttf
    pkgs.nerd-fonts.blex-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

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
      # persistent-apps = [
      #   "/Applications/Arc.app"
      #   "/Applications/Obsidian.app"
      #   "/System/Applications/Messages.app"
      #   "/Applications/WhatsApp.app"
      #   "${pkgs.discord}/Applications/Discord.app"
      #   "/Applications/Slack.app"
      #   "/Applications/1Password.app"
      #   "/Applications/Ghostty.app"
      #   "/Applications/Postico.app"
      #   "/Applications/IntelliJ IDEA.app"
      #   "/System/Applications/Mail.app"
      #   "/System/Applications/Calendar.app"
      #   "/Applications/Todoist.app"
      #   "/System/Applications/Music.app"
      #   "/System/Applications/News.app"
      # ];
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
      "com.jetbrains.intellij" = {
        ApplePressAndHoldEnabled = false;
      };
      "com.jetbrains.intellij.ce" = {
        ApplePressAndHoldEnabled = false;
      };
      # "com.pointum.hazeover" = {
      #   Enabled = 1;
      #   Intensity = "70";
      # };
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
            menuBarItemsToActivate = {
              "com.apple.controlcenter-Battery" = "Battery";
            };
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
            triggerSpecificDict = {
              Script = "tmutil status | awk -F'=' '/Running/ {print $2*1}'";
            };
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
            menuBarItemsToActivate = {
              "com.apple.controlcenter-WiFi" = "Wi-Fi";
            };
            name = "Show Wi-Fi when Wi-Fi condition met";
            triggerSpecificDict = {
              ShowOn = "AllDisconnected";
            };
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
        # exportPath = "${builtins.getEnv "HOME"}/Library/Mobile Documents/com~apple~CloudDocs/ScreenShots";
      };
    };

  };

  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = "/Applications";
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

}
