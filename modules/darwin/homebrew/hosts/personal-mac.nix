# Personal Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    taps = [
      "wontaeyang/hrm"
    ];
    brews = [
      "mockery"
      "mole"
      "pyenv-virtualenv"
    ];
    casks = [
      "1password"
      "1password-cli"
      # "capacities"
      "hrm"
    ];
    masApps = {
      # "WhatsApp" = 310633997;
    };
  };
}
