{ pkgs, lib, ... }:
{
  # Vicinae - High-performance native launcher for Linux
  # Replaces wofi with more features: clipboard history, calculator, file search, extensions
  # Platform-guarded for NixOS only (not available on macOS)

  config = lib.mkIf pkgs.stdenv.isLinux {
    services.vicinae = {
      enable = true;
      autoStart = true;

      settings = {
        # Favicon service for web search results
        faviconService = "twenty"; # twenty | google | none

        # Font configuration
        font.size = 11;

        # Navigation behavior
        popToRootOnClose = false;

        # Enable file search in root search
        rootSearch.searchFiles = true;

        # Theme selection - matches existing aesthetic
        # Available: gruvbox-dark, catppuccin-mocha, kanagawa, nord, dracula, tokyo-night-storm
        theme.name = "gruvbox-dark";

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
  };
}
