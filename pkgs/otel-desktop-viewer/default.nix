{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
}:

let
  version = "0.4.1";

  assets = {
    aarch64-darwin = {
      name = "otel-desktop-viewer_darwin_arm64.tar.gz";
      hash = "sha256-PRFZhcz4/cR+XSyWsZ8gayM3zjbLsZBF8g7CpgPz4hk=";
    };
    x86_64-darwin = {
      name = "otel-desktop-viewer_darwin_amd64.tar.gz";
      hash = "sha256-X8QhZzxQ7gCfdk+KEu2xe29zrLblq9aKkHpRw2eCmg4=";
    };
    aarch64-linux = {
      name = "otel-desktop-viewer_linux_arm64.tar.gz";
      hash = "sha256-qAfk54YQoOfuBxXWP824myq6Y6NeuonSeY1c80mfxJ0=";
    };
    x86_64-linux = {
      name = "otel-desktop-viewer_linux_amd64.tar.gz";
      hash = "sha256-3NxnPLLveTSZzgIpga89xWrSEW3BsehMHg8S5bWeO/s=";
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
