{ inputs, ... }:
{
  flake.modules.homeManager.fd =
    { ... }:
    {
      programs.fd = {
        enable = true;
      };
    };
}
