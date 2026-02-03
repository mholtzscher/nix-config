# Homebrew common configuration (nix-darwin)
{ config, lib, ... }:
let
  cfg = config.myFeatures.homebrewCommon;
in
{
  options.myFeatures.homebrewCommon = {
    enable = lib.mkEnableOption "homebrew common config" // {
      default = true;
      description = "Common homebrew config for all macOS hosts";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.darwin.homebrewCommon = {
      homebrew = {
        enable = true;
        onActivation = {
          cleanup = "zap";
          upgrade = true;
          autoUpdate = true;
        };
        taps = [
          "hashicorp/tap"
          "FelixKratz/formulae"
          "jetbrains/utils"
        ];
        brews = [
          "awscli"
          "borders"
          "JetBrains/utils/kotlin-lsp"
          "mas"
          "podman"
        ];
        casks = [
          "arc"
          "bartender"
          "cleanshot"
          "deskpad"
          "docker-desktop"
          "ghostty"
          "jetbrains-toolbox"
          "nightfall"
          "obsidian"
          "postman"
          "raycast"
          "slack"
          "visual-studio-code"
        ];
        masApps = {
          Numbers = 409203825;
          Hazeover = 430798174;
          Postico = 6446933691;
          Todoist = 585829637;
        };
      };
    };
  };
}
