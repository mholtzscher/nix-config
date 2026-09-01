{
  autoPatchelfHook,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
}:

let
  plannotatorTuiVersion = "0.6.0";
  plannotatorTuiAssets = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-CW0MWr2oYsFzrHN5xgb4kJdo9DRYMzrHBr1u3gQkyLc=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-ysoUurI13uJkF7+mtJ/nC3v2uYWvnqStTNa6JPVs7DE=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-TnOR+KDIFQEkaWdaxpVpJS60nNK56XV6UJOmrdOgeHI=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-36DmwO75zhymTqexjzdlE2Sp8cLAphW91E+JjSRGkgo=";
    };
  };
  plannotatorTuiAsset =
    plannotatorTuiAssets.${stdenv.hostPlatform.system}
      or (throw "herdr-annotate is not packaged for ${stdenv.hostPlatform.system}");
  plannotatorTui = fetchurl {
    url = "https://github.com/plannotator/plannotator-tui/releases/download/v${plannotatorTuiVersion}/plannotator-tui-${plannotatorTuiAsset.target}";
    inherit (plannotatorTuiAsset) hash;
  };
in
stdenv.mkDerivation rec {
  pname = "herdr-annotate";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "plannotator";
    repo = "herdr-annotate";
    rev = "bccf884b874f5f39ccbef1bb6ac67625c5fb5d54";
    hash = "sha256-h3ibUCd2uLtQENU0IRNJzefZH2pnK13mzCoHmGc1EeU=";
  };

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r herdr-plugin.toml package.json plannotator-tui.version scripts skills src "$out/"
    install -m755 ${plannotatorTui} "$out/bin/plannotator-tui"
    echo ${lib.escapeShellArg plannotatorTuiVersion} > "$out/bin/plannotator-tui.version"

    runHook postInstall
  '';

  meta = {
    description = "Add comments to copied terminal text in Herdr";
    homepage = "https://github.com/plannotator/herdr-annotate";
    platforms = builtins.attrNames plannotatorTuiAssets;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
}
