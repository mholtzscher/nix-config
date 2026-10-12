{
  pkgs,
  ...
}:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac
  # Work-specific shell aliases and environment are handled by shared modules.
  programs.ssh.settings.nixos-desktop.IdentityFile = "~/.ssh/id_ed25519_nixos_desktop";

  home = {

    # Work-specific programs and packages
    packages = with pkgs; [
      mkalias
      mariadb.client
    ];
  };
}
