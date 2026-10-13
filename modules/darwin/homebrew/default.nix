# Homebrew module - macOS package management
# Common configuration shared across all macOS hosts
# Host-specific packages defined in ./hosts/*.nix
{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      # Preserve native apps and their data during the handoff to Mise.
      cleanup = "none";
      upgrade = true;
      autoUpdate = true;
    };
    taps = [
      "hashicorp/tap"
    ];
    masApps = {
      # "Numbers" = 361304891;
      # "Postico" = 6446933691;
      # "Todoist" = 585829637;
    };
  };

}
