{ pkgs, ... }:
{
  # Gaming configuration for NixOS Desktop
  # Includes Steam, MangoHud, GameMode, and related gaming tools

  home-manager.sharedModules = [
    {
      home = {
        # Gaming packages
        packages = with pkgs; [
          # Steam integration tools
          mangohud # Performance overlay (FPS, temps, RAM/VRAM)
          gamemode # CPU governor optimization for games
          gamescope # SteamOS compositor for better compatibility
          protonup-qt # GUI for managing Proton-GE versions
          steamtinkerlaunch # Advanced Steam game tweaking tool

          # Additional gaming utilities (optional, uncomment as needed)
          # lutris # Game launcher for various platforms
          # heroic # Epic Games & GOG launcher
          # bottles # Windows app runner using Wine
          # wine # Windows compatibility layer
          # winetricks # Wine helper scripts
        ];

        # MangoHud configuration for gaming performance overlay
        file.".config/MangoHud/MangoHud.conf".text = ''
          # Performance metrics to display
          fps
          frametime=0
          cpu_temp
          gpu_temp
          ram
          vram

          # Display position and styling
          position=top-left
          background_alpha=0.5
          font_size=24

          # Toggle key (Shift_R+F12)
          toggle_hud=Shift_R+F12
        '';

        # Optional: Steam launch options helper script
        file.".local/bin/steam-gamemode" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            # Launch Steam with gamemode and mangohud
            exec gamemoderun mangohud steam "$@"
          '';
        };

        # Optional: Proton environment variables for better compatibility
        sessionVariables = {
          # Enable DXVK async for better performance (use with caution in online games)
          # DXVK_ASYNC = "1";

          # Enable FSR for upscaling support
          # WINE_FULLSCREEN_FSR = "1";

          # Force Proton to use specific version (example)
          # STEAM_COMPAT_DATA_PATH = "$HOME/.steam/steam/steamapps/compatdata";
        };
      };
    }
  ];
}
