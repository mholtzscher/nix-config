{ pkgs, ... }:
{
  # Wallpaper rotation using wpaperd
  # Efficient daemon with built-in timer, GPU transitions, and low resource usage
  # Perfect for large collections (500+ images)

  home-manager.sharedModules = [
    {
      # wpaperd configuration via home-manager
      services.wpaperd = {
        enable = true;
        settings = {
          # Configure for all displays using "any"
          # Valid modes: stretch, center, fit, tile, fit-border-color (NOT "fill")
          any = {
            path = "/home/michael/Pictures/wallpapers";
            duration = "1m";  # Change wallpaper every minute
            mode = "fit-border-color";  # Fits image and fills borders with edge color (best for ultrawide)
            sorting = "random";  # random or sequential
          };
        };
      };

      # Add wpaperd control utility to packages for manual control
      # Commands: wpaperctl next, previous, pause, resume, status
      home.packages = with pkgs; [ wpaperd ];
    }
  ];
}
