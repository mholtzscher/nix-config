{
  # NixOS Desktop Environment Configuration
  # This module provides a complete desktop environment setup including:
  # - Niri window manager with Waybar status bar
  # - Vicinae application launcher
  # - Gaming tools and configuration
  # - Theming (GTK, Qt, dark mode)
  # - Wallpaper daemon
  # - Web applications as native apps

  imports = [
    ./composition.nix # Niri window manager + Waybar status bar
    ./launcher.nix # Vicinae application launcher
    ./gaming.nix # Gaming tools (Steam, MangoHud, etc.)
    ./theme.nix # GTK/Qt theming and dark mode
    ./wallpaper.nix # Wallpaper daemon configuration
    ./webapps.nix # Web applications as native apps
  ];
}
