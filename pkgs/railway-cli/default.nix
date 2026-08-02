{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "5.30.3";

  # Map Nix system strings to Rust target triples used in release tarballs
  rustTargets = {
    aarch64-darwin = "aarch64-apple-darwin";
    x86_64-darwin = "x86_64-apple-darwin";
    aarch64-linux = "aarch64-unknown-linux-musl";
    x86_64-linux = "x86_64-unknown-linux-musl";
  };

  hashes = {
    aarch64-darwin = "sha256-ih1Jcwhb5xZNBJ0tv35ohsZhBZU91z3SRkkW4KP4C7Q=";
    x86_64-darwin = "sha256-OTef2PNV+rksmwtnn6Q0SzS8xHvakuDgUpzbxApi+II=";
    aarch64-linux = "sha256-kdbH1ugYVb3GCdeQHkSOgmMcI8BdFDvKytAwMACxYD0=";
    x86_64-linux = "sha256-VsFN9VBZGaimu4/r6BH35O3Hy4EJ80hH2FmIwykmFso=";
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
