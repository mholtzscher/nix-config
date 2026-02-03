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

      # Import dendritic feature modules (but not host modules to avoid recursion)
      # Feature modules export to flake.modules.homeManager.*, etc.
      imports = [
        ./modules/_base.nix
        (inputs.import-tree ./modules/features)
      ];

      flake = {
        # Host configurations - defined separately to avoid infinite recursion
        # Hosts reference inputs.self.modules.homeManager.* which requires them
        # to be defined outside of the module tree
        darwinConfigurations = {
          "Michaels-M1-Max" = import ./hosts/personal-mac.nix { inherit inputs; };
          "Michael-Holtzscher-Work" = import ./hosts/work-mac.nix { inherit inputs; };
        };

        nixosConfigurations = {
          nixos-desktop = import ./hosts/nixos-desktop.nix { inherit inputs; };
        };

        homeConfigurations = {
          wanda = import ./hosts/wanda.nix { inherit inputs; };
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
