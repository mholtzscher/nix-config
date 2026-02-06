# Personal Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    taps = [
      "opgginc/opencode-bar"
    ];
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
      "opencode-desktop"
      "opencode-bar"
    ];
    masApps = {
      "WhatsApp" = 310633997;
    };
  };
}
