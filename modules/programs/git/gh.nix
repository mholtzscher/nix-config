{ inputs, ... }:
{
  flake.modules.homeManager.gh =
    { ... }:
    {
      programs.gh = {
        enable = true;
      };
    };
}
