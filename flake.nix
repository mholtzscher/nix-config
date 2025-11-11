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
    ghostty-shader-playground = {
      url = "github:KroneCorylus/ghostty-shader-playground";
      flake = false;
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
    };
    catppuccin.url = "github:catppuccin/nix";
    beads = {
      url = "github:steveyegge/beads";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
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
      ghostty-shader-playground,
      nix-colors,
      vicinae,
      catppuccin,
      beads,
      niri,
    }:
    let
      # Import lib helpers for creating system configurations
      lib = import ./lib { inherit inputs self; };
    in
    {
      darwinConfigurations = {
        # Personal Mac (M1 Max)
        "Michaels-M1-Max" = lib.mkDarwinSystem { hostPath = ./hosts/darwin/personal-mac.nix; };

        # Work Mac
        "Michael-Holtzscher-Work" = lib.mkDarwinSystem { hostPath = ./hosts/darwin/work-mac.nix; };
      };

      nixosConfigurations = {
        # NixOS Desktop
        nixos = lib.mkNixOSSystem {
          hostPath = ./hosts/nixos/desktop.nix;
          system = "x86_64-linux";
        };
      };
    };
}
