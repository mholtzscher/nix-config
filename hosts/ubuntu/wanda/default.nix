# Wanda - Ubuntu server with standalone home-manager
# Headless services host + NAS gateway
#
# Activation:
#   nh home switch /home/michael/nix-config#wanda
#
# Or with the flake installed:
#   home-manager switch --flake /home/michael/nix-config#wanda
{ pkgs, inputs, ... }:
{
  imports = [
    ../../../modules/home-manager/home.nix
    ../../../modules/home-manager/hosts/wanda
  ];

  home = {
    username = "michael";
    homeDirectory = "/home/michael";
  };

  # Wanda-specific targets (Ubuntu uses different service manager integration)
  targets.genericLinux.enable = true;
}
