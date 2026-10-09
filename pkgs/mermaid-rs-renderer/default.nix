{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
}:

let
  version = "0.3.1";

  assets = {
    aarch64-darwin = {
      name = "mmdr-aarch64-apple-darwin.tar.gz";
      hash = "sha256-Vi0CUMuFiK3v45iiPku99n8kKEnqjYiMOCaLzD7fMiM=";
    };
    x86_64-darwin = {
      name = "mmdr-x86_64-apple-darwin.tar.gz";
      hash = "sha256-rQNSWIIrYO5rs8CGw8cyXa/jFL+rFqO7mdaSwY+tWc0=";
    };
    aarch64-linux = {
      name = "mmdr-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-p0oSGi3TvI0wwXyVSzoDbnRnpTshUy6IlgGibMbcOdk=";
    };
    x86_64-linux = {
      name = "mmdr-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-4dpHt1h2m/8huCpID61kCjuJOpD8DcMhVRSG+LUMcgA=";
    };
  };

  asset =
    assets.${stdenv.hostPlatform.system}
      or (throw "mermaid-rs-renderer is not packaged for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "mermaid-rs-renderer";
  inherit version;

  src = fetchurl {
    url = "https://github.com/1jehuang/mermaid-rs-renderer/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;

  installPhase = ''
    runHook preInstall
    install -Dm755 mmdr "$out/bin/mmdr"
    runHook postInstall
  '';

  meta = {
    description = "Fast Mermaid diagram renderer in Rust";
    homepage = "https://github.com/1jehuang/mermaid-rs-renderer";
    license = lib.licenses.mit;
    mainProgram = "mmdr";
    platforms = builtins.attrNames assets;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
