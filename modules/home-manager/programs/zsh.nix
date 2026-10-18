{
  pkgs,
  lib,
  isDarwin,
  ...
}:
{
  # Macs use /bin/zsh; keep the Nix binary on Linux.
  # Mise owns the writable startup files on both platforms.
  home.packages = lib.optionals (!isDarwin) [ pkgs.zsh ];
}
