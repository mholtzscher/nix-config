{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "5.37.4";

  # Map Nix system strings to Rust target triples used in release tarballs
  rustTargets = {
    aarch64-darwin = "aarch64-apple-darwin";
    x86_64-darwin = "x86_64-apple-darwin";
    aarch64-linux = "aarch64-unknown-linux-musl";
    x86_64-linux = "x86_64-unknown-linux-musl";
  };

  hashes = {
    aarch64-darwin = "sha256-d2sQNqEw64ubAFzoUhBzTwIttA/5Vl9uj4YXWXqdsLM=";
    x86_64-darwin = "sha256-4nrpjWqjeLHXjE8j41QYNdC5Oc+MuJhlrq1rrP2p5So=";
    aarch64-linux = "sha256-xEwaf8x1UwDySkmUG0n0/BUySptn+tqAGKfeYLNMnAc=";
    x86_64-linux = "sha256-sMZhRPxO66hG6tFmNSpY4Ji7P9lyvMLmqWDT+395/74=";
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
