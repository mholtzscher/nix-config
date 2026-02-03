# NixOS Desktop system module
# Base system configuration for NixOS desktop
{
  flake.modules.nixos.desktopSystem = {
    # Compatibility: legacy host sets user shell = zsh
    programs.zsh.enable = true;

    # Required by legacy config (NVIDIA, etc.)
    nixpkgs.config.allowUnfree = true;
  };
}
