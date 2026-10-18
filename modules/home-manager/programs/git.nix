{
  pkgs,
  lib,
  isDarwin,
  ...
}:
{
  # Mise bootstrap supplies Git on Macs; keep Nix Git on Linux.
  # Git configuration, LFS, and review tools are already managed by Mise.
  home.packages = lib.optionals (!isDarwin) [ pkgs.git ];
}
