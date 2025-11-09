{ pkgs, ... }:
{
  # Shared wallpaper configuration for Wayland compositors
  # Uses swaybg which works with both Hyprland and Niri

  # Wallpaper package
  home.packages = with pkgs; [ swaybg ];

  # Wallpaper file setup
  home.file.".config/wallpapers/current.jpg".source = ../../files/wallpapers/aishot-3308.jpg;

  # Systemd service for swaybg (works across Wayland compositors)
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i /home/michael/.config/wallpapers/current.jpg -m fill";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
