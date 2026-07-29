{ inputs, pkgs, ... }:
{
  programs = {
    devenv = {
      enable = true;
      package = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.devenv;
      enableNushellIntegration = true;
    };

    direnv = {
      enable = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
