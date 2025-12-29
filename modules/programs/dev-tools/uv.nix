{ inputs, ... }:
{
  flake.modules.homeManager.uv =
    { ... }:
    {
      programs.uv = {
        enable = true;
      };
    };
}
