{ pkgs, ... }:
{
  # Enable ratbagd daemon for gaming mouse configuration (used by Piper)
  services.ratbagd.enable = true;

  home-manager.sharedModules = [
    {
      home = {
        # Gaming packages
        packages = with pkgs; [
          # Steam integration tools (Steam itself enabled at system level)
          gamemode # CPU governor optimization for games
          gamescope # SteamOS compositor for better compatibility
          protonup-qt # GUI for managing Proton-GE versions
          steamtinkerlaunch # Advanced Steam game tweaking tool
          vulkan-tools # vkcube and other Vulkan utilities

          # Peripheral configuration
          piper # GUI for configuring gaming mice (uses ratbagd)

          # Additional gaming utilities (optional, uncomment as needed)
          # lutris # Game launcher for various platforms
          # heroic # Epic Games & GOG launcher
          # bottles # Windows app runner using Wine
          # wine # Windows compatibility layer
          # winetricks # Wine helper scripts
        ];

        # Optional: Proton environment variables for better compatibility
        sessionVariables = {
          # DBus configuration for proper session integration
          DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
        };
      };

      # MangoHud performance overlay for gaming
      programs.mangohud = {
        enable = true;
        enableSessionWide = true; # Set MANGOHUD=1 for all Vulkan games
        settings = {
          # Performance metrics
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

          # Display settings
          position = "top-left";
          font_size = 18;
          background_alpha = "0.5";
          round_corners = 5;

          # Toggle key (Right Shift + F12)
          toggle_hud = "Shift_R+F12";
        };
      };
    }
  ];
}
