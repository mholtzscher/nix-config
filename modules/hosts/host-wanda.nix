# Wanda host-specific Home Manager config
{
  flake.modules.homeManager.hostWanda =
    {
      pkgs,
      lib,
      self,
      ...
    }:
    {
      imports = [ self.modules.homeManager.wandaContainers ];

      home.packages = with pkgs; [
        bandwhich
        mtr
        tmux
      ];

      programs.ssh.matchBlocks.nas = {
        host = "nas nas-a nas-b";
        hostname = "nas-a.internal";
        user = "storage";
      };

      programs.firefox.enable = lib.mkForce false;
      programs.ghostty.enable = lib.mkForce false;
      programs.zed-editor.enable = lib.mkForce false;
    };
}
