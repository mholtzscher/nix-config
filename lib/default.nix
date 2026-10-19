{ inputs, self, ... }:
{
  # Builders for NixOS and standalone Linux Home Manager configurations.
  # NixOS Usage:
  #   mkSystem { name = "desktop"; system = "x86_64-linux"; hostPath = ./hosts/nixos/desktop.nix; user = "michael"; graphical = true; gaming = true; }
  mkSystem =
    {
      name,
      system,
      hostPath,
      user ? "michael",
      graphical ? true,
      gaming ? false,
      isWork ? false,
    }:
    let
      # Keep the shared module argument contract; all Nix hosts are now Linux.
      isDarwin = false;
      isLinux = true;

      # Base NixOS modules and their shared argument contract.
      commonModules = [
        hostPath
        ../modules/shared

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
            inherit graphical gaming;
          };
        }

      ];

      # NixOS-specific modules
      nixosModules = [
        inputs.home-manager.nixosModules.home-manager
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
        ../modules/nixos
        inputs.catppuccin.nixosModules.catppuccin

      ]
      ++ (if graphical then [ ../modules/nixos/hosts/nixos-desktop ] else [ ]);

      allModules = commonModules ++ nixosModules;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          self
          user
          isWork
          ;
      };
      modules = allModules;
    };

  # Standalone home-manager configuration for non-NixOS Linux hosts (Ubuntu, Debian, etc.)
  # This creates a home-manager configuration that can be activated without NixOS.
  #
  # Usage:
  #   mkHome { name = "wanda"; system = "x86_64-linux"; hostPath = ./hosts/ubuntu/wanda.nix; user = "michael"; }
  #
  # Activation on target machine:
  #   nix run home-manager -- switch --flake .#wanda
  mkHome =
    {
      name,
      system,
      hostPath,
      user ? "michael",
      isWork ? false,
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      isDarwin = false;
      isLinux = true;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {
        inherit
          inputs
          self
          user
          isWork
          isDarwin
          isLinux
          ;
        currentSystemName = name;
        currentSystemUser = user;
      };

      modules = [
        hostPath

        # Module arguments for home-manager modules
        {
          _module.args = {
            inherit isWork isDarwin isLinux;
            currentSystemName = name;
            currentSystemUser = user;
          };
        }
      ];
    };
}
