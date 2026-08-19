# Work Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    brews = [
      "opencode"
    ];
    casks = [
      "jetbrains-toolbox"
      "handy"
    ];
    masApps = {
      # Empty for now, but keeping structure for future additions
    };
  };
}
