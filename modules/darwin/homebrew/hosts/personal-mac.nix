# Personal Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    taps = [
      "wontaeyang/hrm"
    ];
    brews = [
      "mockery"
      "pyenv-virtualenv"
    ];
    casks = [
      "1password"
      "1password-cli"
      # "capacities"
      "intellij-idea-ce"
      "hrm"
    ];
    masApps = {
      # "WhatsApp" = 310633997;
    };
  };
}
