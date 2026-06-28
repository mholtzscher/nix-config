{
  description = "Multi-platform Nix flake for Darwin and NixOS systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-artifacts = {
      url = "github:mholtzscher/agent-artifacts";
      flake = false;
    };
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
    cloudflare-skills = {
      url = "github:cloudflare/skills";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    mholtzscher-skills = {
      url = "github:mholtzscher/skills";
      flake = false;
    };
    plannotator-skills = {
      url = "github:plannotator/effective-html";
      flake = false;
    };
    vercel-agent-browser = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
    };
    nicobailon-visual-explainer = {
      url = "github:nicobailon/visual-explainer";
      flake = false;
    };
    ugh = {
      url = "github:mholtzscher/ugh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    today = {
      url = "github:mholtzscher/today";
      inputs.nixpkgs.follows = "nixpkgs";
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
    herdr = {
      url = "github:ogulcancelik/herdr";
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
      topiaryNushell,
      ghostty-shader-playground,
      catppuccin,
      niri,
      aerospace-utils,
      open-file,
      melt,
      neovim-nightly,
      quickshell,
      dms,
      llm-agents,
      agent-skills,
      agent-artifacts,
      anthropic-skills,
      cloudflare-skills,
      mattpocock-skills,
      mholtzscher-skills,
      plannotator-skills,
      vercel-agent-browser,
      nicobailon-visual-explainer,
      ugh,
      today,
      helium,
      hunk,
      sem,
      herdr,
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
