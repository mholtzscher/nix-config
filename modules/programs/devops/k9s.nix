{ inputs, ... }:
{
  flake.modules.homeManager.k9s =
    { ... }:
    {
      programs.k9s = {
        enable = true;
      };
    };
}
