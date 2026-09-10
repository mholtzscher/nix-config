{ pkgs, lib, ... }:
{
  imports = [
    ./containers.nix
  ];

  # Wanda-specific CLI tooling and dotfiles
  home.packages = with pkgs; [
    bandwhich
    dive
    jq
    mtr
    sops
  ];

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
