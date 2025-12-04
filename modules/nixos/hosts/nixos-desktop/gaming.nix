{ pkgs, ... }:
{
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
    }
  ];
}
