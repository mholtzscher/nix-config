{ pkgs, ... }:
{
  # Git remains available to bootstrap Mise; config and Git LFS live in Mise.
  home.packages = [ pkgs.git ];
}
