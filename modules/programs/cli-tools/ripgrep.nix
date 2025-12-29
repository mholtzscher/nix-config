{ inputs, ... }:
{
  flake.modules.homeManager.ripgrep =
    { ... }:
    {
      programs.ripgrep = {
        enable = true;
      };
    };
}
