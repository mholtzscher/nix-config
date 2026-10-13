# Homebrew module - macOS package management
# Common configuration shared across all macOS hosts
# Host-specific packages defined in ./hosts/*.nix
{ ... }:
{
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
    ];
    casks = [
      "arc"
      "cleanshot"
      "deskpad"
      "google-chrome"
      # "docker-desktop"
      "raycast"
      "slack"
    ];
    masApps = {
      # "Numbers" = 361304891;
      # "Postico" = 6446933691;
      # "Todoist" = 585829637;
    };
  };

}
