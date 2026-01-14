# Personal Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    brews = [
      "hashicorp/tap/terraform"
      "mockery"
      "pyenv-virtualenv"
    ];
    casks = [
      "1password"
      "1password-cli"
      "capacities"
      "intellij-idea-ce"
    ];
    masApps = {
      "WhatsApp" = 310633997;
    };
  };
}
