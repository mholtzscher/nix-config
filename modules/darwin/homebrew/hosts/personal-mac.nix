# Personal Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    taps = [
      "wontaeyang/hrm"
    ];
    brews = [
      "mole"
      "pyenv-virtualenv"
    ];
    casks = [
      "1password"
      # "capacities"
      "hrm"
    ];
    masApps = {
      # "WhatsApp" = 310633997;
    };
  };
}
