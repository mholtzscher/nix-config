# Zed - editor
{
  flake.modules.homeManager.zed =
    { lib, ... }:
    {
      programs.zed-editor = {
        enable = lib.mkDefault false;
        userSettings = {
          vim_mode = true;
        };
      };
    };
}
