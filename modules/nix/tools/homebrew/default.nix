{ inputs, ... }:
{
  # Homebrew integration for Darwin (macOS)

  flake.modules.darwin.homebrew = {
    imports = [
      inputs.nix-homebrew.darwinModules.nix-homebrew
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
  };
}
