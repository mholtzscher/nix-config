# Work Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    brews = [
      "opencode"
    ];
    casks = [
      "jetbrains-toolbox"
    ];
    masApps = {
      # Empty for now, but keeping structure for future additions
    };
  };
}
