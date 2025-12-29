{ inputs, ... }:
{
  flake.modules.homeManager.bottom =
    { ... }:
    {
      programs.bottom = {
        enable = true;
      };
    };
}
