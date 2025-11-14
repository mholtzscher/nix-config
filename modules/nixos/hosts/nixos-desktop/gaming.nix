{ pkgs, ... }:
{
  # Gaming configuration for NixOS Desktop
  # Includes Steam, GameMode, and related gaming tools

  # Note: Steam is enabled at the system level in hosts/nixos/nixos-desktop.nix
  # This module focuses on user-level gaming packages and configurations

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

          # Additional gaming utilities (optional, uncomment as needed)
          # lutris # Game launcher for various platforms
          # heroic # Epic Games & GOG launcher
          # bottles # Windows app runner using Wine
          # wine # Windows compatibility layer
          # winetricks # Wine helper scripts
        ];

        # Optional: Steam launch options helper script
        file.".local/bin/steam-gamemode" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            # Launch Steam with gamemode
            exec gamemoderun steam "$@"
          '';
        };

        # Optional: Proton environment variables for better compatibility
        sessionVariables = {
          # DBus configuration for proper session integration
          DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";

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
