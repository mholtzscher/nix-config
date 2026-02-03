# NixOS NVIDIA GPU module
# NVIDIA drivers, graphics, and related kernel config
{
  flake.modules.nixos.nvidia =
    { config, ... }:
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
}
