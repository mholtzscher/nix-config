{ inputs, self, ... }:
{
  # Unified helper function to create system configurations for both Darwin and NixOS
  # Inspired by mitchellh/nixos-config unified system builder
  #
  # Darwin Usage:
  #   mkSystem { name = "personal-mac"; system = "aarch64-darwin"; darwin = true; hostPath = ./hosts/darwin/personal-mac.nix; user = "michael"; }
  #
  # NixOS Usage:
  #   mkSystem { name = "desktop"; system = "x86_64-linux"; hostPath = ./hosts/nixos/desktop.nix; user = "michael"; graphical = true; gaming = true; }
  mkSystem =
    {
      name,
      system,
      hostPath,
      user ? "michael",
      darwin ? false,
      graphical ? true,
      gaming ? false,
      isWork ? false,
    }:
    let
      # Heuristics for platform detection
      isDarwin = darwin;
      isLinux = !darwin;

      # Select appropriate system builder function
      systemFunc =
        if isDarwin then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

      # Select appropriate home-manager module
      homeManagerModule =
        if isDarwin then
          inputs.home-manager.darwinModules.home-manager
        else
          inputs.home-manager.nixosModules.home-manager;

      # Common modules shared by both platforms
      commonModules = [
        hostPath
        ../modules/shared
        homeManagerModule

        # Global module arguments - available to all modules
        {
          _module.args = {
            currentSystem = system;
            currentSystemName = name;
            currentSystemUser = user;
            inherit
              isDarwin
              isLinux
              inputs
              isWork
              ;
          }
          // (if isLinux then { inherit graphical gaming; } else { });
        }

        # Home-manager specific module arguments - make variables available without explicit import
        {
          home-manager.sharedModules = [
            {
              _module.args = {
                inherit isWork;
                inherit isDarwin isLinux;
                currentSystemName = name;
                currentSystemUser = user;
              };
            }
          ];
        }
      ];

      # Darwin-specific modules
      darwinModules = [
        ../modules/darwin
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;
        }
      ];

      # NixOS-specific modules
      nixosModules = [
        ../modules/nixos
        inputs.catppuccin.nixosModules.catppuccin

        # Conditional module loading based on feature flags
        (if graphical then inputs.niri.nixosModules.niri else { })
      ];

      # Combine platform-specific modules with common modules
      allModules = commonModules ++ (if isDarwin then darwinModules else nixosModules);
    in
    systemFunc (
      {
        specialArgs = {
          inherit
            inputs
            self
            user
            isWork
            ;
        };
        modules = allModules;
      }
      // (if isLinux then { inherit system; } else { })
    );
}
