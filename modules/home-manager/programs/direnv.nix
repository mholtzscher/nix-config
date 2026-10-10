{ ... }:
{
  programs = {
    devenv = {
      enable = true;
      # devenv was previously pinned from nixpkgs-master for a newer version;
      # nixos-unstable now ships a recent-enough devenv, so this is unused.
      enableNushellIntegration = false;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
