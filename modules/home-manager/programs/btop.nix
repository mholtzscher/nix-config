{ ... }:
{
  programs = {
    btop = {
      enable = true;
      # Theme automatically managed by Stylix via stylix.targets.btop

      settings = {
        # btop-specific configuration
        vim_keys = true;
        rounded_corners = true;
        graph_symbol = "braille";
        update_ms = 2000;
        proc_sorting = "cpu lazy";
        proc_tree = false;

        # Stylix will handle color_theme automatically
        # No need to set it manually
      };
    };
  };
}
