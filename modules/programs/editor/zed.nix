{ inputs, ... }:
{
  flake.modules.homeManager.zed =
    { ... }:
    {
      programs.zed-editor = {
        enable = false;
        userSettings = {
          "vim_mode" = true;
        };
      };
    };
}
