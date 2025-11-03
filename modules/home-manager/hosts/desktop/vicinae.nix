{ ... }:
{
  # Vicinae - High-performance native launcher for Linux
  # Replaces wofi with more features: clipboard history, calculator, file search, extensions
  # Only imported on NixOS via desktop.nix (not available on macOS)

  services.vicinae = {
    enable = true;
    autoStart = true;

    settings = {
      # Favicon service for web search results
      faviconService = "twenty"; # twenty | google | none

      # Font configuration
      font = {
        family = "Iosevka Nerd Font";
        size = 11;
      };

      # Navigation behavior
      popToRootOnClose = false;

      # Enable file search in root search
      rootSearch.searchFiles = true;

      # Theme selection - Catppuccin Mocha
      # Available: gruvbox-dark, catppuccin-mocha, kanagawa, nord, dracula, tokyo-night, tokyo-night-storm
      theme.name = "catppuccin-mocha";

      # Window appearance
      window = {
        csd = true; # Client-side decorations
        opacity = 0.95;
        rounding = 10;
      };
    };

    # Extensions can be added here declaratively
    # extensions = [];
  };
}
