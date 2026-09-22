{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "5.59.0";

  # Map Nix system strings to Rust target triples used in release tarballs
  rustTargets = {
    aarch64-darwin = "aarch64-apple-darwin";
    x86_64-darwin = "x86_64-apple-darwin";
    aarch64-linux = "aarch64-unknown-linux-musl";
    x86_64-linux = "x86_64-unknown-linux-musl";
  };

  hashes = {
    aarch64-darwin = "sha256-VLB5mwqCSLwdkT3fIWtFHxV7KoilgzaRbPzBzdG0G/A=";
    x86_64-darwin = "sha256-cMqB10f/Rwoh7gV8k11HNdN9X5+rmzHFwfa0QA6Zao0=";
    aarch64-linux = "sha256-rTMG9Ubrg1V8vcWEz707kCBqSaJrDErXepkTlQXRwPE=";
    x86_64-linux = "sha256-1t7CiheDSLb+7jUOrm0TfhToiUjqLXKJ7gN5kaM1ULE=";
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
