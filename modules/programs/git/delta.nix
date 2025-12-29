{ inputs, ... }:
{
  flake.modules.homeManager.delta =
    { ... }:
    {
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          side-by-side = true;
          dark = true;
        };
      };
    };
}
