{ inputs, ... }:
{
  flake.modules.homeManager.eza =
    { ... }:
    {
      programs.eza = {
        enable = true;
        git = true;
        extraOptions = [
          "--header"
        ];
      };
    };
}
