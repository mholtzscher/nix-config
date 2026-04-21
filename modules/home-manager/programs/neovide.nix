{
  pkgs,
  lib,
  config,
  isDarwin,
  ...
}:
let
  # Use the same font as ghostty for consistency
  fontFamily = "Iosevka Nerd Font";
in
{
  programs.neovide = {
    enable = true;
    package = pkgs.neovide;

    settings = {
      # Window frame style. Options:
      # - "full": Standard window decorations (title bar, borders)
      # - "none": No window decorations (borderless)
      # - "buttonless": Title bar without buttons (macOS only)
      # - "transparent": Transparent title bar (macOS only)
      frame = if isDarwin then "full" else "none";

      # Detach from the terminal when launching. Set to true to prevent
      # blocking the terminal that launched neovide.
      fork = false;

      # Animate the cursor and UI while neovim is idle. Set to false to
      # disable animations when not actively typing (saves battery/CPU).
      idle = true;

      # Start window maximized. Mutually exclusive with 'size' and 'grid'.
      maximized = false;

      # Enable vertical sync to prevent screen tearing. May add slight
      # input latency; disable if you prefer lower latency over visual quality.
      vsync = true;

      # Hide the window title on macOS (doesn't affect other platforms).
      # Creates a cleaner look when combined with frame = "buttonless".
      title-hidden = false;

      # Use native macOS tabs instead of vim tabs. Requires system-native-tabs
      # to be enabled. This setting is macOS-only.
      tabs = true;

      # Enable multigrid rendering for smoother animations and floating windows.
      # Set to true to disable multigrid (not recommended unless you have issues).
      no-multigrid = false;

      # Path to neovim binary. Uses the one in PATH by default, but we
      # explicitly set it to use the home-manager managed neovim.
      neovim-bin = lib.getExe config.programs.neovim.package;

      # Font configuration. Neovide uses bundled Fira Code Nerd Font by default
      # if not specified. We use Iosevka for consistency with ghostty.
      font = {
        # Primary font family. Can be a string or array of strings for fallback.
        normal = [ fontFamily ];

        # Font size in points. Neovide allows fractional sizes for precise tuning.
        size = if isDarwin then 13.0 else 11.0;

        # Hinting: "none", "slight", "full". Controls font edge clarity.
        # "full" provides sharpest text but may look thinner.
        hinting = "full";

        # Edging: "antialias", "subpixelantialias". Controls how font edges are smoothed.
        # "antialias" is better for high-DPI displays.
        edging = "antialias";
      };

      # macOS-specific settings (only applied on Darwin)
      # These control system integration features unique to macOS
      system-native-tabs = lib.mkIf isDarwin false; # Use native macOS tabs
      system-pinned-hotkey = lib.mkIf isDarwin "cmd+ctrl+z"; # Toggle pinned window
      system-switcher-hotkey = lib.mkIf isDarwin "cmd+ctrl+n"; # Tab switcher
      system-tab-prev-hotkey = lib.mkIf isDarwin "cmd+shift+["; # Previous tab
      system-tab-next-hotkey = lib.mkIf isDarwin "cmd+shift+]"; # Next tab
    };
  };
}
