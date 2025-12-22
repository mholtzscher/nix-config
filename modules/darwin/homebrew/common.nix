# Common Homebrew configuration shared across all macOS hosts
# Host-specific packages should be defined in ./hosts/*.nix
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
      "sst/tap"
    ];
    brews = [
      "awscli"
      "borders"
      "mas"
      "sst/tap/opencode"
    ];
    casks = [
      "arc"
      "bartender"
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
