{ pkgs, ... }:
{
  # Keep a Nix Zsh binary available; Mise owns the writable startup files.
  home.packages = [ pkgs.zsh ];
}
