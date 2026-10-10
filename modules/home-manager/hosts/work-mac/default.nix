{
  pkgs,
  inputs,
  ...
}:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac
  # Atuin, agent configuration, and work-only CLI tools are managed by Mise.
  programs.ssh.settings.nixos-desktop.IdentityFile = "~/.ssh/id_ed25519_nixos_desktop";

  home = {

    # Work-specific programs and packages
    packages = with pkgs; [
      aerospace
      inputs.aerospace-utils.packages.${pkgs.stdenv.hostPlatform.system}.default
      mkalias
      mariadb.client
    ];
  };
}
