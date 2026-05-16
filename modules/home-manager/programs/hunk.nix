# Hunk - review-first terminal diff viewer
# Uses the hunk flake's home-manager module for proper config and git integration support.
{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [ inputs.hunk.homeManagerModules.default ];

  programs.hunk = {
    enable = true;
    settings = {
      theme = "graphite";
      mode = "auto";
      line_numbers = true;
    };
  };
}
