# Work Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    brews = [
      "tfenv"
    ];
    casks = [
      "intellij-idea" # Paid version
    ];
    masApps = {
      # Empty for now, but keeping structure for future additions
    };
  };
}
