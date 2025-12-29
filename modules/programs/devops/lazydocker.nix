{ inputs, ... }:
{
  flake.modules.homeManager.lazydocker =
    { ... }:
    {
      programs.lazydocker = {
        enable = true;
      };
    };
}
