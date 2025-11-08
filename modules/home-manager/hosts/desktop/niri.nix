{ pkgs, ... }:
{
  # Niri scrollable-tiling Wayland compositor config
  # This is a minimal experimental setup - feel free to customize!

  # Create Niri configuration file from external KDL file
  home.file.".config/niri/config.kdl".text = builtins.readFile ../../files/niri/config.kdl;

  # Copy wallpaper to a known location
  home.file.".config/wallpapers/current.jpg".source = ../../files/wallpapers/aishot-3308.jpg;

  # Install swaybg for wallpaper
  home.packages = with pkgs; [ swaybg ];
}
