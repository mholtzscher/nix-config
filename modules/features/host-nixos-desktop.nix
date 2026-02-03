# NixOS Desktop host-specific Home Manager config
{ config, lib, ... }:
let
  cfg = config.myFeatures.hostNixosDesktop;
in
{
  options.myFeatures.hostNixosDesktop = {
    enable = lib.mkEnableOption "nixos-desktop host config" // {
      default = true;
      description = "Host-specific home-manager settings for nixos-desktop";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.hostNixosDesktop =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        # Solaar config for Logitech MX Master 3S
        xdg.configFile."solaar/config.yaml".text = lib.generators.toYAML { } [
          "1.1.16"
          {
            _NAME = "MX Master 3S for Mac";
            _modelId = "B03400000000";
            _serial = "6EBEDCC2";
            _unitId = "6EBEDCC2";
            _wpid = "B034";

            # Scroll diversion OFF - fixes scroll wheel after KVM switch
            hires-scroll-mode = false;
            thumb-scroll-mode = false;

            # Other scroll settings
            hires-smooth-invert = false;
            hires-smooth-resolution = false;
            thumb-scroll-invert = false;
            scroll-ratchet = 2;
            smart-shift = 12;

            # DPI
            dpi = 1000;
          }
        ];

        home.packages = with pkgs; [
          awscli2
          vesktop

          nautilus
          imv
          zathura
          brightnessctl
          pavucontrol
          steam-run
          qpwgraph
        ];

        xdg.configFile."DankMaterialShell/themes/catppuccin-mocha-lavender.json".source =
          ../../modules-legacy/home-manager/files/dms/catppuccin-mocha-lavender.json;

        xdg.configFile."DankMaterialShell/settings.json".text = builtins.toJSON {
          currentThemeName = "custom";
          customThemeFile = "${config.xdg.configHome}/DankMaterialShell/themes/catppuccin-mocha-lavender.json";
          fontFamily = "Iosevka Nerd Font";
          useFahrenheit = true;
          use24HourClock = false;

          acLockTimeout = 600;
          acMonitorTimeout = 720;
          acSuspendTimeout = 0;

          lockBeforeSuspend = true;
          fadeToLockEnabled = true;
          fadeToLockGracePeriod = 5;
          fadeToDpmsEnabled = true;
          fadeToDpmsGracePeriod = 5;
        };

        services.easyeffects.enable = true;

        systemd.user.services."1password" = {
          Unit = {
            Description = "1Password";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
            Restart = "on-failure";
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
  };
}
