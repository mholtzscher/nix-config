{ inputs, ... }:
{
  # Gaming services for NixOS (Steam, MangoHud, etc.)

  flake.modules.nixos.gaming = {
    programs.steam = {
      enable = true;
    };

    programs.gamemode = {
      enable = true;
    };
  };

  flake.modules.homeManager.gaming =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        gamemode
        gamescope
        protonup-qt
        steamtinkerlaunch
        vulkan-tools
      ];

      home.sessionVariables = {
        DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
      };

      programs.mangohud = {
        enable = true;
        enableSessionWide = true;
        settings = {
          fps = true;
          frametime = true;
          frame_timing = true;
          gpu_stats = true;
          gpu_temp = true;
          gpu_power = true;
          cpu_stats = true;
          cpu_temp = true;
          ram = true;
          vram = true;
          position = "top-left";
          font_size = 18;
          background_alpha = "0.5";
          round_corners = 5;
          toggle_hud = "Shift_R+F12";
        };
      };
    };
}
