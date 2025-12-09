# Hardware configuration for nixos-desktop
# Generated from nixos-generate-config
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/fb9deae2-f218-4069-9f5e-897b6ecb36f8";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5299-3C02";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/ff127c89-8abe-4db5-8cf9-90c416dc5633"; }
  ];

  # Additional hard drive mounts
  # Games drive - ext4 formatted, mounted in user's home directory

  fileSystems."/home/michael/games" = {
    device = "/dev/disk/by-uuid/b17a1789-1f79-4f5f-8d3c-7f431dbd5b43";
    fsType = "ext4";
    options = [
      "defaults" # Standard mount options
      "nofail" # Don't fail boot if drive is missing
      "noatime" # Don't update access times (better performance for games)
    ];
  };

  # Enables DHCP on each ethernet and wireless interface.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
