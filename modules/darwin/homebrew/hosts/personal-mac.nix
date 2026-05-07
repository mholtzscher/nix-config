# Personal Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    taps = [
      "wontaeyang/hrm"
    ];
    brews = [
      "hashicorp/tap/terraform"
      "mockery"
      "ollama"
      "pyenv-virtualenv"
    ];
    casks = [
      "1password"
      "1password-cli"
      "capacities"
      "intellij-idea-ce"
      "hrm"
    ];
    masApps = {
      # "WhatsApp" = 310633997;
    };
  };
}
