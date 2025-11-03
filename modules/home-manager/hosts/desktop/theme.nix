{ ... }:
{
  # Desktop theming configuration for dark mode support
  # This ensures GTK, Qt, and other applications properly detect and use dark mode

  # GTK dark mode preferences
  # Catppuccin already sets the GTK theme, we just ensure dark mode is preferred
  gtk = {
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt theme configuration
  # Let Catppuccin manage Qt theming via kvantum for consistent appearance
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # Set dark mode preference via dconf (for GNOME/GTK apps)
  # This is the system-wide setting that XDG-compliant apps check
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
