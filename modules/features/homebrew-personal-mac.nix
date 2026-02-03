# Homebrew host-specific config: personal mac
{ config, lib, ... }:
let
  cfg = config.myFeatures.homebrewPersonalMac;
in
{
  options.myFeatures.homebrewPersonalMac = {
    enable = lib.mkEnableOption "homebrew personal mac" // {
      default = true;
      description = "Personal mac homebrew packages";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.darwin.homebrewPersonalMac = {
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
          "opencode-desktop"
        ];
        masApps = {
          WhatsApp = 310633997;
        };
      };
    };
  };
}
