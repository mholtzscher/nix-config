# Personal Mac (M1 Max) - Dendritic Host Configuration
{
  config,
  lib,
  inputs,
  ...
}:
{
  # Define the darwinConfiguration for this host
  flake.darwinConfigurations."Michaels-M1-Max" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Import catppuccin for theming (darwin system level)
      inputs.catppuccin.darwinModules.catppuccin

      # Configure home-manager with dendritic feature modules
      (
        { config, ... }:
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.michael = {
              imports = [
                # Enable dendritic feature modules
                # These come from the flake.modules.homeManager namespace
                inputs.self.modules.homeManager.bat
                inputs.self.modules.homeManager.eza
                inputs.self.modules.homeManager.fzf
                inputs.self.modules.homeManager.ripgrep
                inputs.self.modules.homeManager.zoxide
                inputs.self.modules.homeManager.fd

                # Catppuccin theming for home-manager
                inputs.catppuccin.homeModules.catppuccin
              ];
            };
          };
        }
      )

      # Legacy bridge: import the original host config
      # This ensures all the existing config still works during migration
      ../../hosts/darwin/personal-mac.nix
    ];
  };
}
