# Hunk - review-first terminal diff viewer
# Uses the hunk flake's home-manager module for proper config and git integration support.
{
  inputs,
  ...
}:
{
  imports = [ inputs.hunk.homeManagerModules.default ];

  programs.hunk = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      mode = "auto";
      line_numbers = true;
    };
  };
}
