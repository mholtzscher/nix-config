# NixOS Desktop system module
# Base system configuration for NixOS desktop
{ config, lib, ... }:
let
  cfg = config.myFeatures.nixosDesktopSystem;
in
{
  options.myFeatures.nixosDesktopSystem = {
    enable = lib.mkEnableOption "NixOS Desktop system config" // {
      default = true;
      description = "NixOS Desktop base system configuration";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "michael";
      description = "Primary user for NixOS Desktop";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.nixos.desktopSystem =
      { user, ... }:
      {
        # Compatibility: legacy host sets user shell = zsh
        programs.zsh.enable = true;

        # Required by legacy config (NVIDIA, etc.)
        nixpkgs.config.allowUnfree = true;
      };
  };
}
