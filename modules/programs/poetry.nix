# Poetry - Python dependency manager
{
  flake.modules.homeManager.poetry =
    { lib, ... }:
    {
      programs.poetry = {
        enable = lib.mkDefault false;
        settings = {
          virtualenvs.create = true;
          virtualenvs.in-project = true;
        };
      };
    };
}
