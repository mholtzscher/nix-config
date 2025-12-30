{ ... }:
{
  # Vicinae - High-performance native launcher for Linux
  # Features: clipboard history, calculator, file search, extensions

  home-manager.sharedModules = [
    {
      services.vicinae = {
        enable = true;

        systemd.enable = true;

        settings = {
          font = {
            normal = {
              family = "Iosevka Nerd Font";
              size = 11;
            };
          };

          theme = {
            name = "catppuccin-mocha";
          };

          # Window appearance
          launcher_window = {
            opacity = 0.90;
            csd = {
              enabled = true;
              rounding = 10;
            };
            layer_shell = {
              enabled = false;
            };
          };

          close_on_focus_loss = true;

          # Favicon service for web search results
          favicon_service = "google"; # twenty | google | none

          # Navigation behavior
          pop_to_root_on_close = true;

          # Enable file search in root search
          search_files_in_root = true;
        };

        # Extensions can be added here declaratively
        # extensions = [];
      };
    }
  ];
}
