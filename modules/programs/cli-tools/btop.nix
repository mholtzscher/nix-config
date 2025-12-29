{ inputs, ... }:
{
  flake.modules.homeManager.btop =
    { ... }:
    {
      programs.btop = {
        enable = true;
        settings = {
          vim_keys = true;
          rounded_corners = true;
          graph_symbol = "braille";
          update_ms = 2000;
          proc_sorting = "cpu lazy";
          proc_tree = false;
        };
      };
    };
}
