{ pkgs, lib, ... }:
let
  wandaHomeFlake = "/home/michael/nix-config";
in
{
  imports = [
    ./containers.nix
    ./komodo.nix
  ];

  # Wanda-specific CLI tooling and dotfiles
  home.packages = with pkgs; [
    bandwhich
    mtr
  ];

  # Let bare `nh home` commands select Wanda's standalone Home Manager output.
  programs.nh.homeFlake = wandaHomeFlake;

  # Disable GUI programs on headless server
  programs.ghostty.enable = lib.mkForce false;
}
