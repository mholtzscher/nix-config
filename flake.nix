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
    opencode = {
      url = "github:sst/opencode";
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
      opencode,
      open-file,
      melt,
    }:
    let
      # Import lib helpers for creating system configurations
      lib = import ./lib { inherit inputs self; };
    in
    {
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

        # Wanda • headless services + NAS gateway
        wanda = lib.mkSystem {
          name = "wanda";
          system = "x86_64-linux";
          hostPath = ./hosts/nixos/wanda;
          user = "michael";
          graphical = false;
          gaming = false;
        };
      };
    };
}
