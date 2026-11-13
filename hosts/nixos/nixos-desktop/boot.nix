{ pkgs, ... }:
{
  boot = {
    # Temporary diagnostic rollback for tearing after the November 12 update.
    # NVIDIA follows this kernel via config.boot.kernelPackages in gpu.nix.
    # Remove after testing/resolving the regression to resume kernel security updates.
    kernelPackages = pkgs.linuxPackagesFor (
      pkgs.linuxKernel.kernels.linux_6_18.override {
        argsOverride = rec {
          version = "6.18.54";
          modDirVersion = version;
          src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
            hash = "sha256-nfMLAt2BArvQvlJVYojvaIndvn8d25b7+EfQvs8+rKw=";
          };
        };
      }
    );

    # Bootloader configuration
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Increase vm.max_map_count for games that need it (some Proton games)
    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
  };
}
