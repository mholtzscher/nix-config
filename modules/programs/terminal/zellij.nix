{ inputs, ... }:
{
  flake.modules.homeManager.zellij =
    { ... }:
    {
      programs.zellij = {
        enable = true;
      };

      xdg.configFile."zellij/config.kdl".source = ./files/zellij.kdl;
    };
}
