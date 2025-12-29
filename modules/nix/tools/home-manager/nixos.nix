{ inputs, ... }:
{
  # Home-manager integration for NixOS

  flake.modules.nixos.home-manager = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = { inherit inputs; };

      # Pass constants to home-manager modules
      sharedModules = [
        inputs.self.modules.generic.constants
      ];
    };
  };
}
