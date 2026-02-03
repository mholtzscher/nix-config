# Pyenv - Python version manager
{
  flake.modules.homeManager.pyenv =
    { lib, ... }:
    {
      programs.pyenv.enable = lib.mkDefault false;
    };
}
