{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.19.4";

  assets = {
    aarch64-darwin = {
      name = "plannotator-darwin-arm64";
      hash = "sha256-ySS+sR/7d2NvbApD4hNEuA8kmwbR5bMvGQKpg5viIfo=";
    };
    x86_64-linux = {
      name = "plannotator-linux-x64";
      hash = "sha256-s9FpCmEqI/rTLWLVZAtbmo4QZ0kIC/NLlusAYdahn0o=";
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
