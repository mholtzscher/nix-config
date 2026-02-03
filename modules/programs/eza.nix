# Eza - A modern replacement for ls
{
  flake.modules.homeManager.eza = {
    programs.eza = {
      enable = true;
      git = true;
      extraOptions = [
        "--header"
      ];
    };
  };
}
