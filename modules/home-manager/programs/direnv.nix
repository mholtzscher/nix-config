{ ... }:
{
  programs = {
    devenv = {
      enable = true;
      # package = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.devenv;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
