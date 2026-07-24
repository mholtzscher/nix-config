{ ... }:
{
  programs = {
    devenv = {
      enable = true;
      enableNushellIntegration = true;
    };

    direnv = {
      enable = true;
      enableNushellIntegration = false;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
