{ inputs, ... }:
{
  flake.modules.homeManager.poetry =
    { ... }:
    {
      programs.poetry = {
        enable = false;
        settings = {
          virtualenvs.create = true;
          virtualenvs.in-project = true;
        };
      };
    };
}
