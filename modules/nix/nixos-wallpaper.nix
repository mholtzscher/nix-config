# NixOS Wallpaper module
# Awww wallpaper daemon with rotation timer
{
  flake.modules.homeManager.nixosWallpaper =
    {
      pkgs,
      inputs,
      config,
      ...
    }:
    let
      awww = inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww;

      # Script to set a random wallpaper using awww
      wallpaper-rotate = pkgs.writeShellScriptBin "wallpaper-rotate" ''
        WALLPAPER_DIR="${config.home.homeDirectory}/Pictures/wallpapers"

        # Find a random image
        WALLPAPER=$(${pkgs.findutils}/bin/find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/shuf -n 1)

        if [ -n "$WALLPAPER" ]; then
          ${awww}/bin/awww img "$WALLPAPER" --transition-type random --resize fit
        fi
      '';
    in
    {
      # Add awww and control script to packages
      home.packages = [
        awww
        wallpaper-rotate
      ];

      # awww-daemon systemd service
      systemd.user.services.awww-daemon = {
        Unit = {
          Description = "awww wallpaper daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${awww}/bin/awww-daemon";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      # Wallpaper rotation service (triggered by timer)
      systemd.user.services.wallpaper-rotate = {
        Unit = {
          Description = "Rotate wallpaper";
          After = [ "awww-daemon.service" ];
          Requires = [ "awww-daemon.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${wallpaper-rotate}/bin/wallpaper-rotate";
        };
      };

      # Timer to rotate wallpaper every 5 minutes
      systemd.user.timers.wallpaper-rotate = {
        Unit = {
          Description = "Rotate wallpaper every 5 minutes";
        };
        Timer = {
          OnCalendar = "*:0/5:00"; # Every 5 minutes
          Persistent = true;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
}
