{ pkgs, lib, ... }:
{
  imports = [
    ./containers.nix
  ];

  # Wanda-specific CLI tooling and dotfiles
  # Note: helix is already enabled via programs.helix in shared config
  home.packages = with pkgs; [
    bandwhich
    dive
    jq
    mtr
    sops
    tmux
  ];

  # Disable GUI programs on headless server
  programs.firefox.enable = lib.mkForce false;
  programs.ghostty.enable = lib.mkForce false;
  programs.zed-editor.enable = lib.mkForce false;

  # Disable catppuccin theming that requires GUI packages
  catppuccin.firefox.enable = lib.mkForce false;

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
