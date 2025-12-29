{ inputs, ... }:
{
  # Generic module for nix settings - usable on both NixOS and Darwin
  flake.modules.generic.nix-settings =
    { pkgs, ... }:
    {
      # Allow unfree packages (like Discord, Obsidian, etc.)
      nixpkgs.config.allowUnfree = true;

      # Set Git commit hash for version tracking
      system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

      # Nix package manager settings
      nix = {
        # Enable flakes and new nix command
        settings = {
          experimental-features = "nix-command flakes";

          # Cachix caches
          extra-substituters = [
            "https://mholtzscher.cachix.org"
            "https://vicinae.cachix.org"
          ];
          extra-trusted-public-keys = [
            "mholtzscher.cachix.org-1:liIrpcru/aB3IiCNR62EYTSRPHo/UYYMzYVpYZuiz6w="
            "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
          ];
        };

        # Use nix package from nixpkgs
        package = pkgs.nix;

        # Automatic garbage collection
        gc = {
          automatic = true;
          options = "--delete-older-than 30d";
        };
      };
    };
}
