{
  pkgs,
  isDarwin,
  ...
}:
{
  # Configuration, theme, and shaders are tracked by Mise.
  catppuccin.ghostty.enable = false;
  programs = {
    ghostty = {
      enable = true;
      package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    };
  };
}
