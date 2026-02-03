# NixOS NVIDIA GPU module
# NVIDIA drivers, graphics, and related kernel config
{ config, lib, ... }:
let
  cfg = config.myFeatures.nixosNvidia;
in
{
  options.myFeatures.nixosNvidia = {
    enable = lib.mkEnableOption "NixOS NVIDIA support" // {
      default = true;
      description = "NVIDIA GPU drivers and graphics configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.nixos.nvidia =
      { config, pkgs, ... }:
      {
        # X server with NVIDIA driver (needed even for Wayland)
        services.xserver = {
          enable = true;
          videoDrivers = [ "nvidia" ];
        };

        hardware = {
          # NVIDIA GPU support
          nvidia = {
            modesetting.enable = true;
            powerManagement.enable = false;
            powerManagement.finegrained = false;
            open = false;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.stable;
          };

          # Graphics drivers for gaming (Vulkan, OpenGL with 32-bit support)
          graphics = {
            enable = true;
            enable32Bit = true; # Required for 32-bit games
          };
        };

        # Kernel parameters for NVIDIA + Wayland
        boot.kernelParams = [
          "nvidia-drm.modeset=1"
        ];
      };
  };
}
