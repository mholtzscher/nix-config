{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.10.0";

  assets = {
    aarch64-darwin = {
      assetName = "hunkdiff-darwin-arm64";
      hash = "sha256-cdiwcZPevnbhlpsHzPeRVsb5WQdunaNlTCKh+XwarUU=";
    };
    x86_64-darwin = {
      assetName = "hunkdiff-darwin-x64";
      hash = "sha256-70O4DI3+7ZuZstem8QeiL/qrj9M65nYVflqzqUlpnSY=";
    };
    aarch64-linux = {
      assetName = "hunkdiff-linux-arm64";
      hash = "sha256-epaG0urTx3nqr2mIClkDLzrxf+gOZE4EDyC0YyEPq8M=";
    };
    x86_64-linux = {
      assetName = "hunkdiff-linux-x64";
      hash = "sha256-ND3Kb1u0B5O+joNCvE4LzJjYpSFnt5QWDFGmuAmYns8=";
    };
  };

  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "hunk is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "hunk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/modem-dev/hunk/releases/download/v${version}/${asset.assetName}.tar.gz";
    inherit (asset) hash;
  };

  sourceRoot = asset.assetName;

  installPhase = ''
    runHook preInstall

    install -Dm755 hunk "$out/bin/hunk"

    runHook postInstall
  '';

  meta = {
    description = "A review-first terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = builtins.attrNames assets;
  };
}
