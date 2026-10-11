# Hunk - review-first terminal diff viewer
# Uses the upstream module for configuration and llm-agents for the package.
{
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.hunk.homeManagerModules.default ];

  programs.hunk = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hunk;
    settings = {
      theme = "catppuccin-mocha";
      mode = "auto";
      line_numbers = true;
    };
  };
}
