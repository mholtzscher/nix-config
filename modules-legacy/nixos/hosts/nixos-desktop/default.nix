{
  # NixOS Desktop Environment Configuration
  # This module provides a complete desktop environment setup including:
  # - Niri window manager + DankMaterialShell integration
  # - Gaming tools and configuration
  # - Theming (GTK, Qt, dark mode)
  # - Web applications as native apps

  imports = [
    ./packages.nix # Desktop packages, fonts, 1Password
    ./composition.nix # Niri window manager + DMS keybinds/integration
    ./gaming.nix # Gaming tools (Steam, MangoHud, etc.)
    ./webapps.nix # Web applications as native apps
  ];
}
