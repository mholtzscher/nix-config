# Hardware configuration for Wanda
# NVMe + LVM root, EFI boot
{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Root on LVM
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bb354ec5-7ee5-4d25-a31c-4fc046ed2d29";
    fsType = "ext4";
  };

  # Boot partition (ext4)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/bdefd927-fbc8-41e7-9b21-71167fb4b79a";
    fsType = "ext4";
  };

  # EFI System Partition
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/2F57-18FC";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Swap file (Ubuntu uses /swap.img)
  swapDevices = [
    { device = "/swap.img"; }
  ];

  networking.useDHCP = lib.mkDefault false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
