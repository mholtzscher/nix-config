{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.7.0";

  assets = {
    aarch64-darwin = {
      name = "ghui-darwin-arm64.tar.gz";
      hash = "sha256-83bKAvX2PtxGY27dGBT0/R913JMEJUJ7ckDF4AYnwFo=";
    };
    x86_64-darwin = {
      name = "ghui-darwin-x64.tar.gz";
      hash = "sha256-MOacKIKBqJZ8x9IDMObkyBG0njFIpohhA/sX0v1uh0k=";
    };
    aarch64-linux = {
      name = "ghui-linux-arm64.tar.gz";
      hash = "sha256-6daT6VPuIdLk2zBNqvkcjgaJuKplToCnaRQBzJLl+fM=";
    };
    x86_64-linux = {
      name = "ghui-linux-x64.tar.gz";
      hash = "sha256-xKQSm1Xza1Z/htoWr2TLOUENbvXCtFNyQy+gAAzOtk4=";
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
