{
  inputs,
  pkgs,
  ...
}:
{
  programs = {
    mise = {
      enable = true;
      enableNushellIntegration = false; # Nushell config is managed by Mise.
      mutableSettings = true;
      # Bootstrap and dotfile history require the pinned upstream Mise.
      # Upstream tests fail on Linux's macOS fixtures, and the macOS test
      # binary exceeds the ARM64 linker's branch-distance limit.
      package = inputs.mise.packages.${pkgs.stdenv.hostPlatform.system}.mise.overrideAttrs (_: {
        doCheck = false;
      });
    };
  };
}
