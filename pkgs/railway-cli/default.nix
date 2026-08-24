{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "5.43.2";

  # Map Nix system strings to Rust target triples used in release tarballs
  rustTargets = {
    aarch64-darwin = "aarch64-apple-darwin";
    x86_64-darwin = "x86_64-apple-darwin";
    aarch64-linux = "aarch64-unknown-linux-musl";
    x86_64-linux = "x86_64-unknown-linux-musl";
  };

  hashes = {
    aarch64-darwin = "sha256-6ofmwPyhzdZX+7RO18zz3bHFCCxOsNgFDcVMiBmtaOk=";
    x86_64-darwin = "sha256-uqfMszq0rT/AFHwZDODHCg/Gz+0Jj82jO+4OlcLauN0=";
    aarch64-linux = "sha256-0J5/LR1oSylj+FYkaxJ7+5sk9dXUBj3bbl8fyyW8cQM=";
    x86_64-linux = "sha256-5VFZTD8xwz4m1I17PeOEIJjfdrTnC/i6XqTbsfWc4iI=";
  };

  rustTarget =
    rustTargets.${stdenvNoCC.hostPlatform.system}
      or (throw "railway-cli is not packaged for ${stdenvNoCC.hostPlatform.system}");

  hash =
    hashes.${stdenvNoCC.hostPlatform.system}
      or (throw "railway-cli is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "railway";
  inherit version;

  src = fetchurl {
    url = "https://github.com/railwayapp/cli/releases/download/v${version}/railway-v${version}-${rustTarget}.tar.gz";
    inherit hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 railway "$out/bin/railway"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line interface for interacting with Railway projects";
    homepage = "https://github.com/railwayapp/cli";
    license = licenses.mit;
    mainProgram = "railway";
    platforms = builtins.attrNames rustTargets;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
