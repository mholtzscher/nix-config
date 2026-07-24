{ ... }:
{
  programs = {
    devenv = {
      enable = true;
      enableNushellIntegration = false;
    };

    direnv = {
      enable = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
