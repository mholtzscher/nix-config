{ inputs, ... }:
{
  # Wallpaper rotation using wpaperd

  flake.modules.homeManager.wallpaper =
    { pkgs, ... }:
    {
      services.wpaperd = {
        enable = true;
        settings = {
          any = {
            path = "/home/michael/Pictures/wallpapers";
            duration = "1m";
            mode = "fit-border-color";
            sorting = "random";
          };
        };
      };

      home.packages = with pkgs; [ wpaperd ];
    };
}
