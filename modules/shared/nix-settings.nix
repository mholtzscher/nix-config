{ pkgs, self, ... }:
{
  # Cross-platform nix configuration settings
  # Extracted from flake.nix to reduce duplication

  # Allow unfree packages (like Discord, Obsidian, etc.)
  nixpkgs.config.allowUnfree = true;

  # Set Git commit hash for version tracking
  # Works on both darwin (darwin-version) and NixOS (nixos-version)
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Nix package manager settings
  nix = {
    # Enable flakes and new nix command
    settings.experimental-features = "nix-command flakes";

    # Use the nix package from nixpkgs
    package = pkgs.nix;

    # Automatic garbage collection
    # Removes generations older than 30 days
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };
}
