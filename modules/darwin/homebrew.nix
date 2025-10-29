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
      # "nikitabobko/tap"
      "sst/tap"
      # "steveyegge/beads"
    ];
    brews = [
      "awscli"
      "asdf"
      # "bd"
      "borders"
      "JetBrains/utils/kotlin-lsp"
      "mas"
      "sst/tap/opencode"
    ];
    casks = [
      # "aerospace"
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
    ];
    masApps = {
      "Numbers" = 409203825;
      "Hazeover" = 430798174;
      "Postico" = 6446933691;
      "Todoist" = 585829637;
    };
  };

}
