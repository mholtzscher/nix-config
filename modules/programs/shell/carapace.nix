{ inputs, ... }:
{
  flake.modules.homeManager.carapace =
    { pkgs, ... }:
    {
      programs.carapace = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
      };
    };
}
