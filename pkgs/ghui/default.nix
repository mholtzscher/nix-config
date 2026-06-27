{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.8.0";

  assets = {
    aarch64-darwin = {
      name = "ghui-darwin-arm64.tar.gz";
      hash = "sha256-2fcDEYYM2K918PJXIzoKNmsYvg5n25YlwhhoX5i4TeA=";
    };
    x86_64-darwin = {
      name = "ghui-darwin-x64.tar.gz";
      hash = "sha256-ZW5n0tfYPSFU/nsMwB+iaPDS6zZ9emp6cW3n4zLBysM=";
    };
    aarch64-linux = {
      name = "ghui-linux-arm64.tar.gz";
      hash = "sha256-KdReX0d41/4mkRCMyGAqES0C5UgMBuyb+zhweJhM16M=";
    };
    x86_64-linux = {
      name = "ghui-linux-x64.tar.gz";
      hash = "sha256-EH3keYdlBHVsBVrUpZMZS0mNW+nXKH2QLijoh1Tgp/0=";
    };
  };

  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "ghui is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "ghui";
  inherit version;

  src = fetchurl {
    url = "https://github.com/kitlangton/ghui/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 ghui "$out/bin/ghui"

    runHook postInstall
  '';

  meta = {
    description = "A GitHub TUI";
    homepage = "https://github.com/kitlangton/ghui";
    license = lib.licenses.mit;
    mainProgram = "ghui";
    platforms = builtins.attrNames assets;
  };
}
