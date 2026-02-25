{ ... }:
{
  programs.zellij = {
    enable = true;
  };

  # Use the KDL config file directly since home-manager's zellij module
  # doesn't properly escape attribute names with spaces in plugin configs
  xdg.configFile."zellij/config.kdl".source = ../files/zellij.kdl;
  xdg.configFile."zellij/layouts/vibes.kdl".source = ../files/zellij-layout-vibes.kdl;
}
