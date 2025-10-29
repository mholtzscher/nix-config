{ inputs, self, ... }:
{
  # Helper function to create a nix-darwin system configuration
  # Abstracts common module imports and setup
  mkDarwinSystem =
    hostPath:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit inputs self;
      };
      modules = [
        hostPath
        ../modules/darwin
        ../modules/shared
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.home-manager.darwinModules.home-manager
      ];
    };

  # Helper function to create a NixOS system configuration
  # Abstracts common module imports and setup
  mkNixOSSystem =
    hostPath:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs self;
      };
      modules = [
        hostPath
        ../modules/nixos
        ../modules/shared
        inputs.home-manager.nixosModules.home-manager
      ];
    };
}
