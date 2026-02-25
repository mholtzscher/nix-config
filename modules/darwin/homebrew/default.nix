# Homebrew module - macOS package management
# Common configuration shared across all macOS hosts
# Host-specific packages defined in ./hosts/*.nix
{ ... }:
{
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
      "1jehuang/mmdr"
    ];
    brews = [
      "awscli"
      "borders"
      "JetBrains/utils/kotlin-lsp"
      "mas"
      "podman"
      "1jehuang/mmdr/mmdr"
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
      "Numbers" = 409203825;
      "Hazeover" = 430798174;
      "Postico" = 6446933691;
      "Todoist" = 585829637;
    };
  };

}
