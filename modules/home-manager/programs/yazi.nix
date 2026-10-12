{ pkgs, ... }:
{
  # Mise owns Yazi and its config; retain the native preview/archive helpers
  # previously supplied by the Nix wrapper. Other helpers already use Mise.
  home.packages = with pkgs; [
    file
    poppler-utils
    _7zz
    imagemagick
    chafa
    resvg
  ];
}
