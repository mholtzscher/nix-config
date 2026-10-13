{
  description = "Multi-platform Nix flake for Darwin and NixOS systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty-shader-playground = {
      url = "github:KroneCorylus/ghostty-shader-playground";
      flake = false;
    };
    catppuccin.url = "github:catppuccin/nix";
    melt = {
      url = "github:mholtzscher/melt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:AlvaroParker/helium-nix";
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
      agenix,
      ghostty-shader-playground,
      catppuccin,
      melt,
      neovim-nightly,
      helium,
      ...
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
          hostPath = ./hosts/darwin/personal-mac;
          user = "michael";
        };

        # Work Mac
        "Michael-Holtzscher-Work" = lib.mkSystem {
          name = "work-mac";
          system = "aarch64-darwin";
          darwin = true;
          hostPath = ./hosts/darwin/work-mac;
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
      homeConfigurations = rec {
        # Wanda - Ubuntu server with home-manager
        # Activation: `nh home switch` on Wanda or
        # `home-manager switch --flake .#wanda` elsewhere.
        wanda = lib.mkHome {
          name = "wanda";
          system = "x86_64-linux";
          hostPath = ./hosts/ubuntu/wanda;
          user = "michael";
        };

        # nh auto-detects standalone configurations as $USER@$HOSTNAME.
        "michael@wanda" = wanda;
      };
    };
}
