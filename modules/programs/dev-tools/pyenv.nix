{ inputs, ... }:
{
  flake.modules.homeManager.pyenv =
    { ... }:
    {
      programs.pyenv = {
        enable = false;
      };
    };
}
