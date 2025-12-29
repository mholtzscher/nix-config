{ inputs, ... }:
{
  # Home-manager integration for Darwin

  flake.modules.darwin.home-manager = {
    imports = [
      inputs.home-manager.darwinModules.home-manager
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
