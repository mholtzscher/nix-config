{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
}:

let
  version = "0.5.0";

  assets = {
    aarch64-darwin = {
      name = "otel-desktop-viewer_darwin_arm64.tar.gz";
      hash = "sha256-5KAFH4J+akD1Kwl/SQ14Mq+FuuV39LM6aamGESx2GKQ=";
    };
    x86_64-darwin = {
      name = "otel-desktop-viewer_darwin_amd64.tar.gz";
      hash = "sha256-spxRISFOiUuL6+3wRQmwD5dsDSC6jMK/Z3v3CJwatr4=";
    };
    aarch64-linux = {
      name = "otel-desktop-viewer_linux_arm64.tar.gz";
      hash = "sha256-dK5UICtZUwDMU/z3DBx9MU7MT187gPwHU6gXubPZO0M=";
    };
    x86_64-linux = {
      name = "otel-desktop-viewer_linux_amd64.tar.gz";
      hash = "sha256-QAZDzU5pErSQGiXlHh/1goFYBvQZ9WDoh0niFTkxQoY=";
    };
  };

  asset =
    assets.${stdenv.hostPlatform.system}
      or (throw "otel-desktop-viewer is not packaged for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "otel-desktop-viewer";
  inherit version;

  src = fetchurl {
    url = "https://github.com/CtrlSpice/otel-desktop-viewer/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  sourceRoot = ".";

  # Linux releases are built against glibc and libstdc++ outside the Nix store.
  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;

  installPhase = ''
    runHook preInstall

    install -Dm755 otel-desktop-viewer "$out/bin/otel-desktop-viewer"

    runHook postInstall
  '';

  meta = {
    description = "Receive and visualize OpenTelemetry traces, metrics, and logs locally";
    homepage = "https://github.com/CtrlSpice/otel-desktop-viewer";
    license = lib.licenses.asl20;
    mainProgram = "otel-desktop-viewer";
    platforms = builtins.attrNames assets;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
