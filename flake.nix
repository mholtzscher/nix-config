{
  description = "Multi-platform Nix flake for Darwin and NixOS systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naws = {
      url = "github:mholtzscher/naws";
      flake = false;
    };
    topiaryNushell = {
      url = "github:blindFS/topiary-nushell";
      flake = false;
    };
    tokyonight = {
      url = "github:folke/tokyonight.nvim";
      flake = false;
    };
    ghostty-shader-playground = {
      url = "github:KroneCorylus/ghostty-shader-playground";
      flake = false;
    };
    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      home-manager,
      naws,
      topiaryNushell,
      tokyonight,
      ghostty-shader-playground,
      omarchy-nix,
    }:
    let
      # Import lib helpers for creating system configurations (reserved for future use)
      # lib = import ./lib { inherit inputs self; };

      # Darwin-specific configuration
      darwinConfiguration =
        { ... }:
        {
          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;
        };
    in
    {
      darwinConfigurations = {
        # Personal Mac (M1 Max)
        "Michaels-M1-Max" = nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            ./hosts/darwin/personal-mac.nix
            ./modules/darwin
            ./modules/shared
            darwinConfiguration
            inputs.nix-homebrew.darwinModules.nix-homebrew
            inputs.home-manager.darwinModules.home-manager
          ];
        };

        # Work Mac
        "Michael-Holtzscher-Work" = nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            ./hosts/darwin/work-mac.nix
            ./modules/darwin
            ./modules/shared
            darwinConfiguration
            inputs.nix-homebrew.darwinModules.nix-homebrew
            inputs.home-manager.darwinModules.home-manager
          ];
        };
      };

      nixosConfigurations = {
        # NixOS Desktop (GNOME)
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            ./hosts/nixos/desktop.nix
            ./modules/nixos
            ./modules/shared
            inputs.home-manager.nixosModules.home-manager
          ];
        };

        # NixOS Desktop with Omarchy (Hyprland)
        nixos-omarchy = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            ./hosts/nixos/desktop-omarchy.nix
            ./modules/nixos
            ./modules/shared
            inputs.omarchy-nix.nixosModules.default
            inputs.home-manager.nixosModules.home-manager
            {
              omarchy = {
                full_name = "Michael Holtzscher";
                email_address = "michael@holtzscher.org";
                theme = "tokyo-night";
              };

              home-manager.users.michael = {
                imports = [ inputs.omarchy-nix.homeManagerModules.default ];
              };
            }
          ];
        };
      };
    };
}
