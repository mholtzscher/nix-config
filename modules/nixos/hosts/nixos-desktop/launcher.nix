{ ... }:
{
  # Vicinae - High-performance native launcher for Linux
  # Features: clipboard history, calculator, file search, extensions

  home-manager.sharedModules = [
    {
      services.vicinae = {
        enable = true;

        settings = {
          font = {
            normal = "Iosevka Nerd Font";
            size = 11;
          };

          theme.name = "catppuccin-mocha";

          # Window appearance
          window = {
            csd = true; # Client-side decorations
            opacity = 0.90;
            rounding = 10;
          };

          closeOnFocusLoss = true;

          # Favicon service for web search results
          faviconService = "google"; # twenty | google | none

          # Navigation behavior
          popToRootOnClose = true;

          # Enable file search in root search
          rootSearch.searchFiles = true;
        };

        # Extensions can be added here declaratively
        # extensions = [];
      };
    }
  ];
}
