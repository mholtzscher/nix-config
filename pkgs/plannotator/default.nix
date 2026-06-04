{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.19.27";

  assets = {
    aarch64-darwin = {
      name = "plannotator-darwin-arm64";
      hash = "sha256-3KawFZVwa3jeD3rj2WGZiIlIdW9Ue83x2/yYOfm9toQ=";
    };
    x86_64-linux = {
      name = "plannotator-linux-x64";
      hash = "sha256-m9zKN6QQh3tGmq3/q8Q8daQgevaja/GA2U6ujKKh2Lc=";
    };
  };

  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "plannotator is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "plannotator";
  inherit version;

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/plannotator"

    runHook postInstall
  '';

  meta = {
    description = "Interactive plan review CLI for AI coding agents";
    homepage = "https://github.com/backnotprop/plannotator";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "plannotator";
    platforms = builtins.attrNames assets;
  };
}
