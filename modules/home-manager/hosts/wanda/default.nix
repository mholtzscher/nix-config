{ pkgs, lib, ... }:
{
  imports = [
    ./containers.nix
  ];

  # Wanda-specific CLI tooling and dotfiles
  home.packages = with pkgs; [
    bandwhich
    bottom
    dive
    helix
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
    matchBlocks."nas" = {
      host = "nas nas-a nas-b";
      hostname = "nas-a.internal";
      user = "storage";
    };
  };
}
