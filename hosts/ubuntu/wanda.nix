# Wanda - Ubuntu server with standalone home-manager
# Headless services host + NAS gateway
#
# Activation:
#   nix run home-manager -- switch --flake ~/.config/nix-config#wanda
#
# Or with the flake installed:
#   home-manager switch --flake ~/.config/nix-config#wanda
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules-legacy/home-manager/home.nix
    ../../modules-legacy/home-manager/hosts/wanda
  ];

  home = {
    username = "michael";
    homeDirectory = "/home/michael";
  };

  # Wanda-specific targets (Ubuntu uses different service manager integration)
  targets.genericLinux.enable = true;
}
