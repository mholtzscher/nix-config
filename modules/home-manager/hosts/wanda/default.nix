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
    dive
    jq
    mtr
    sops
  ];

  # Let bare `nh home` commands select Wanda's standalone Home Manager output.
  programs.nh.homeFlake = wandaHomeFlake;
  programs.nushell.extraConfig = lib.mkAfter ''
    $env.NH_HOME_FLAKE = "${wandaHomeFlake}"
  '';

  # Disable GUI programs on headless server
  programs.ghostty.enable = lib.mkForce false;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Michael Holtzscher";
      email = "michael@holtzscher.com";
    };
  };

  programs.ssh = {
    enable = true;
    settings."nas nas-a nas-b" = {
      HostName = "nas-a.internal";
      User = "storage";
    };
  };
}
