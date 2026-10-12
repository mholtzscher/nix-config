# Work Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    casks = [
      "jetbrains-toolbox"
      "handy"
    ];
    masApps = {
      # Empty for now, but keeping structure for future additions
    };
  };
}
