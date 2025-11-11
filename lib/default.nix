{ inputs, self, ... }:
{
  # Helper function to create a nix-darwin system configuration
  # Abstracts common module imports and setup
  # Usage: mkDarwinSystem { hostPath = ./hosts/darwin/personal-mac.nix; user = "michael"; }
  mkDarwinSystem =
    {
      hostPath,
      user ? "michael",
    }:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit inputs self user;
      };
      modules = [
        hostPath
        ../modules/darwin
        ../modules/shared
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.home-manager.darwinModules.home-manager
        {
          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;
        }
      ];
    };

  # Helper function to create a NixOS system configuration
  # Abstracts common module imports and setup
  # Usage: mkNixOSSystem { hostPath = ./hosts/nixos/desktop.nix; system = "x86_64-linux"; user = "michael"; }
  mkNixOSSystem =
    {
      hostPath,
      system ? "x86_64-linux",
      user ? "michael",
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs self user;
      };
      modules = [
        hostPath
        ../modules/nixos
        ../modules/shared
        inputs.catppuccin.nixosModules.catppuccin
        inputs.home-manager.nixosModules.home-manager
      ];
    };
}
