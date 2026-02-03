# Catppuccin theme defaults
{
  flake.modules.homeManager.catppuccinTheme =
    { inputs, ... }:
    {
      imports = [ inputs.catppuccin.homeModules.catppuccin ];

      catppuccin = {
        enable = true;
        flavor = "mocha";
        zellij.enable = false;
      };
    };
}
