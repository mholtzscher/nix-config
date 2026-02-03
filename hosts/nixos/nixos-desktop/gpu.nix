{
  pkgs,
  config,
  ...
}:
let
  # KVM EDID Override Configuration
  # Fixes monitor resolution issues when switching between KVM inputs
  # Set to true after capturing EDID file with capture-edid script
  enableEdidOverride = true; # EDID override enabled for KVM resolution fix
  edidBinPath = ../../../modules/nixos/hosts/nixos-desktop/edid/dp1.bin;
in
{
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "us";
      variant = "";
    };
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

    # EDID override for KVM - forces kernel to use captured EDID
    # instead of relying on KVM to pass through monitor capabilities
    firmware = pkgs.lib.optionals enableEdidOverride [
      (pkgs.runCommand "edid-firmware" { } ''
        mkdir -p $out/lib/firmware/edid
        cp ${edidBinPath} $out/lib/firmware/edid/dp1.bin
      '')
    ];
  };

  # Kernel parameters for NVIDIA + Wayland
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ]
  ++ pkgs.lib.optional enableEdidOverride "drm.edid_firmware=DP-1:edid/dp1.bin";
}
