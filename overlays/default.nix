# Overlays for package fixes and customizations
final: prev: {
  # Fix vesktop build on Linux - electron files need to be writable for electron-fuses
  # See: https://github.com/NixOS/nixpkgs/issues/XXX
  vesktop = prev.vesktop.overrideAttrs (oldAttrs: {
    preBuild =
      (oldAttrs.preBuild or "")
      + prev.lib.optionalString prev.stdenv.hostPlatform.isLinux ''
        # Copy electron to a writable location (same fix as Darwin)
        cp -r ${prev.electron.dist} electron-dist
        chmod -R u+w electron-dist
      '';

    # Update buildPhase to use our writable electron copy
    buildPhase = ''
      runHook preBuild

      pnpm build
      pnpm exec electron-builder \
        --dir \
        -c.asarUnpack="**/*.node" \
        -c.electronDist=${if prev.stdenv.hostPlatform.isDarwin then "." else "electron-dist"} \
        -c.electronVersion=${prev.electron.version}

      runHook postBuild
    '';
  });
}
