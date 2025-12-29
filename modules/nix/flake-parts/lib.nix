{ inputs, ... }:
{
  flake.lib = rec {
    # Create NixOS configuration from aspect module
    mkNixos =
      system: name:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = system; }
        ];
      };

    # Create Darwin configuration from aspect module
    mkDarwin =
      system: name:
      inputs.nix-darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          { nixpkgs.hostPlatform = system; }
        ];
      };
  };
}
