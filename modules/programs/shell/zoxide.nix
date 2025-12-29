{ inputs, ... }:
{
  flake.modules.homeManager.zoxide =
    { pkgs, ... }:
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
      };
    };
}
