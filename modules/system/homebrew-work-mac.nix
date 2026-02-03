# Homebrew host-specific config: work mac
{
  flake.modules.darwin.homebrewWorkMac = {
    homebrew = {
      brews = [ ];
      casks = [
        "intellij-idea"
      ];
      masApps = { };
    };
  };
}
