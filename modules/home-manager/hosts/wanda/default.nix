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
    userName = "Michael Holtzscher";
    userEmail = "wanda@example.com";
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
