{ pkgs, ... }:
{
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
