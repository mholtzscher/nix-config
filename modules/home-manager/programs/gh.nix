{ pkgs, ... }:
{
  programs = {
    gh = {
      enable = true;
      extensions = [
        pkgs.gh-notify
        pkgs.gh-stack
      ];
    };
  };
}
