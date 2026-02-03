{
  description = "Multi-platform Nix flake for Darwin and NixOS systems (Dendritic Pattern Migration)";

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
    let
      # Import lib helpers for creating system configurations (legacy support during migration)
      lib = import ./lib {
        inherit inputs;
        self = inputs.self;
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # Import dendritic modules from the new modules/ directory
      # During migration, this will be empty or contain new-style modules
      imports = [ (inputs.import-tree ./modules) ];

      flake = {
        # Legacy system configurations (during migration, these use modules-legacy/)
        # These will gradually be replaced by dendritic host modules
        darwinConfigurations = {
          # Personal Mac (M1 Max)
          "Michaels-M1-Max" = lib.mkSystem {
            name = "personal-mac";
            system = "aarch64-darwin";
            darwin = true;
            hostPath = ./hosts/darwin/personal-mac.nix;
            user = "michael";
          };

          # Work Mac
          "Michael-Holtzscher-Work" = lib.mkSystem {
            name = "work-mac";
            system = "aarch64-darwin";
            darwin = true;
            hostPath = ./hosts/darwin/work-mac.nix;
            user = "michaelholtzcher";
            isWork = true;
          };
        };

        nixosConfigurations = {
          # NixOS Desktop
          nixos-desktop = lib.mkSystem {
            name = "nixos-desktop";
            system = "x86_64-linux";
            hostPath = ./hosts/nixos/nixos-desktop;
            user = "michael";
            graphical = true;
            gaming = true;
          };
        };

        # Standalone home-manager configurations for non-NixOS Linux hosts
        homeConfigurations = {
          # Wanda - Ubuntu server with home-manager
          # Activation: home-manager switch --flake .#wanda
          wanda = lib.mkHome {
            name = "wanda";
            system = "x86_64-linux";
            hostPath = ./hosts/ubuntu/wanda.nix;
            user = "michael";
          };
        };

        # Expose lib for external use
        inherit lib;
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
