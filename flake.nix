{
  description = "Multi-platform Nix flake for Darwin and NixOS systems (Dendritic Pattern)";

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
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    naws = {
      url = "github:mholtzscher/naws";
      flake = false;
    };
    topiaryNushell = {
      url = "github:blindFS/topiary-nushell";
      flake = false;
    };
    ghostty-shader-playground = {
      url = "github:KroneCorylus/ghostty-shader-playground";
      flake = false;
    };
    catppuccin.url = "github:catppuccin/nix";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:sst/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aerospace-utils = {
      url = "github:mholtzscher/aerospace-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    open-file = {
      url = "github:mholtzscher/open-file";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    melt = {
      url = "github:mholtzscher/melt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    difftui = {
      url = "github:mholtzscher/difftui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    grepai = {
      url = "github:yoanbernabeu/grepai";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ugh = {
      url = "github:mholtzscher/ugh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # Systems to build for
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      # Import dendritic feature modules from semantic directories
      # Feature modules export to flake.modules.homeManager.*, flake.modules.darwin.*, etc.
      imports = [
        ./modules/_base.nix
        (inputs.import-tree ./modules/programs)
        (inputs.import-tree ./modules/system)
        (inputs.import-tree ./modules/hosts)
        (inputs.import-tree ./modules/nix)
      ];

      flake = {
        # Darwin (macOS) configurations
        darwinConfigurations = {
          "Michaels-M1-Max" =
            let
              user = "michael";
            in
            inputs.nix-darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              specialArgs = {
                inherit inputs user;
                self = inputs.self;
                isWork = false;
              };
              modules = [
                inputs.home-manager.darwinModules.home-manager
                inputs.nix-homebrew.darwinModules.nix-homebrew
                inputs.self.modules.darwin.system
                inputs.self.modules.darwin.base
                inputs.self.modules.darwin.homebrewCommon
                inputs.self.modules.darwin.homebrewPersonalMac
                inputs.self.modules.darwin.hostPersonalMac
                inputs.self.modules.darwin.hmPersonalMac
              ];
            };

          "Michael-Holtzscher-Work" =
            let
              user = "michaelholtzcher";
            in
            inputs.nix-darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              specialArgs = {
                inherit inputs user;
                self = inputs.self;
                isWork = true;
              };
              modules = [
                inputs.home-manager.darwinModules.home-manager
                inputs.nix-homebrew.darwinModules.nix-homebrew
                inputs.self.modules.darwin.system
                inputs.self.modules.darwin.base
                inputs.self.modules.darwin.homebrewCommon
                inputs.self.modules.darwin.homebrewWorkMac
                inputs.self.modules.darwin.hostWorkMac
                inputs.self.modules.darwin.hmWorkMac
              ];
            };
        };

        # NixOS configurations
        nixosConfigurations = {
          nixos-desktop =
            let
              user = "michael";
              system = "x86_64-linux";
            in
            inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = {
                inherit inputs user;
                self = inputs.self;
                isWork = false;
              };
              modules = [
                inputs.home-manager.nixosModules.home-manager
                inputs.catppuccin.nixosModules.catppuccin
                inputs.niri.nixosModules.niri
                inputs.dms.nixosModules.default
                inputs.dms.nixosModules.greeter
                ./hosts/nixos/nixos-desktop
                inputs.self.modules.nixos.desktopSystem
                inputs.self.modules.nixos.packages
                inputs.self.modules.nixos.gaming
                inputs.self.modules.nixos.nvidia
                inputs.self.modules.nixos.steam
                inputs.self.modules.nixos.services
                inputs.self.modules.nixos.wayland
                inputs.self.modules.nixos.greeter
                inputs.self.modules.nixos.desktopHm
              ];
            };
        };

        # Standalone home-manager configurations (non-NixOS Linux)
        homeConfigurations = {
          wanda =
            let
              user = "michael";
              system = "x86_64-linux";
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs { inherit system; };
              extraSpecialArgs = {
                inherit inputs user;
                self = inputs.self;
                isWork = false;
                isDarwin = false;
                isLinux = true;
                currentSystemName = "wanda";
                currentSystemUser = user;
              };
              modules = [
                inputs.self.modules.homeManager.profileCommon
                inputs.self.modules.homeManager.hostWanda
                {
                  home.username = user;
                  home.homeDirectory = "/home/${user}";
                  home.stateVersion = "24.11";
                  programs.home-manager.enable = true;
                  targets.genericLinux.enable = true;
                }
              ];
            };
        };
      };

      # Per-system outputs (packages, devShells, etc.)
      perSystem =
        { system, ... }:
        {
          # No per-system packages defined yet
          # Can add devShells, packages, etc. here during migration
        };
    };
}
