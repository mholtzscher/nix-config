{ inputs, ... }:
{
  flake.modules.homeManager.mise =
    { ... }:
    {
      programs.mise = {
        enable = true;
      };
    };
}
