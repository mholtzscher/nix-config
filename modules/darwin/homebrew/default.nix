# Homebrew module - macOS package management
# Common configuration shared across all macOS hosts
# Host-specific packages defined in ./hosts/*.nix
{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      # Work around nix-darwin a1fa429 emitting the Homebrew 6-incompatible
      # --force-cleanup flag for cleanup = "zap". These flags preserve the
      # intended zap-cleanup behavior.
      cleanup = "none";
      extraFlags = [
        "--cleanup"
        "--zap"
      ];
      upgrade = true;
      autoUpdate = true;
    };
    taps = [
      "hashicorp/tap"
      "FelixKratz/formulae"
      "jetbrains/utils"
      "1jehuang/mmdr"
    ];
    brews = [
      "awscli"
      "borders"
      "JetBrains/utils/kotlin-lsp"
      "mas"
      "1jehuang/mmdr/mmdr"
      "vite-plus"
    ];
    casks = [
      "arc"
      "cleanshot"
      "deskpad"
      "docker-desktop"
      "raycast"
      "slack"
      "visual-studio-code"
    ];
    masApps = {
      # "Numbers" = 361304891;
      # "Postico" = 6446933691;
      # "Todoist" = 585829637;
    };
  };

}
