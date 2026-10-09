# Homebrew module - macOS package management
# Common configuration shared across all macOS hosts
# Host-specific packages defined in ./hosts/*.nix
{ ... }:
{
  nix-homebrew.trust.formulae = [
    "FelixKratz/formulae/borders"
    "JetBrains/utils/kotlin-lsp"
  ];

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
      "vite-plus"
    ];
    casks = [
      "arc"
      "cleanshot"
      "deskpad"
      "google-chrome"
      # "docker-desktop"
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
