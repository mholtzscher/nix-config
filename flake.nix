{
  description = "NixOS and standalone Linux Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    melt = {
      url = "github:mholtzscher/melt";
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
      nixpkgs,
      home-manager,
      catppuccin,
      melt,
      helium,
      ...
    }:
    let
      # Import lib helpers for creating system configurations
      lib = import ./lib { inherit inputs self; };
    in
    {
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
