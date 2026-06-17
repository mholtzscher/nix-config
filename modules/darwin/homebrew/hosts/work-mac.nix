# Work Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    brews = [
    ];
    casks = [
      "jetbrains-toolbox"
      "intellij-idea" # Paid version
    ];
    masApps = {
      # Empty for now, but keeping structure for future additions
    };
  };
}
