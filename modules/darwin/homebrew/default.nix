# Homebrew module - macOS package management
# Common configuration shared across all macOS hosts
# Host-specific packages defined in ./hosts/*.nix
{ ... }:
{
  nix-homebrew.trust.formulae = [
    "FelixKratz/formulae/borders"
  ];

  homebrew = {
    enable = true;
    onActivation = {
      # Preserve native apps and their data during the handoff back to Nix.
      cleanup = "none";
      upgrade = true;
      autoUpdate = true;
    };
    taps = [
      "hashicorp/tap"
      "FelixKratz/formulae"
    ];
    brews = [
      "awscli"
      "borders"
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
