{
  description = "Multi-platform Nix flake for Darwin and NixOS systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.brew-src.follows = "homebrew-brew";
    };
    homebrew-brew = {
      url = "github:Homebrew/brew/5.1.10";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "nix-darwin";
      inputs.home-manager.follows = "home-manager";
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
    aerospace-utils = {
      url = "github:mholtzscher/aerospace-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    llm-agents.url = "github:numtide/llm-agents.nix";
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    skills-agent-artifacts = {
      url = "github:mholtzscher/agent-artifacts";
      flake = false;
    };
    skills-dmmulroy = {
      url = "github:dmmulroy/.dotfiles";
      flake = false;
    };
    skills-anthropic = {
      url = "github:anthropics/skills";
      flake = false;
    };
    skills-cloudflare = {
      url = "github:cloudflare/skills";
      flake = false;
    };
    skills-mattpocock = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    skills-mholtzscher = {
      url = "github:mholtzscher/skills";
      flake = false;
    };
    skills-plannotator = {
      url = "github:plannotator/effective-html";
      flake = false;
    };
    skills-pstack = {
      url = "github:cursor/plugins";
      flake = false;
    };
    skills-vercel = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
    };
    skills-nicobailon = {
      url = "github:nicobailon/visual-explainer";
      flake = false;
    };
    helium = {
      url = "github:AlvaroParker/helium-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sem = {
      url = "github:Ataraxy-Labs/sem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    skills-herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    skills-humanlayer = {
      url = "github:humanlayer/skills";
      flake = false;
    };
    zellmin = {
      url = "github:Brobicheau/zellmin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-brew,
      home-manager,
      agenix,
      topiaryNushell,
      ghostty-shader-playground,
      catppuccin,
      aerospace-utils,
      melt,
      neovim-nightly,
      llm-agents,
      agent-skills,
      skills-agent-artifacts,
      skills-dmmulroy,
      skills-anthropic,
      skills-cloudflare,
      skills-mattpocock,
      skills-mholtzscher,
      skills-plannotator,
      skills-pstack,
      skills-vercel,
      skills-nicobailon,
      helium,
      hunk,
      sem,
      skills-herdr,
      skills-humanlayer,
      zellmin,
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
      homeConfigurations = {
        # Wanda - Ubuntu server with home-manager
        # Activation: home-manager switch --flake .#wanda
        wanda = lib.mkHome {
          name = "wanda";
          system = "x86_64-linux";
          hostPath = ./hosts/ubuntu/wanda;
          user = "michael";
        };
      };
    };
}
