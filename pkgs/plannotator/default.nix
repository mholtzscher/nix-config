{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.22.0";

  assets = {
    aarch64-darwin = {
      name = "plannotator-darwin-arm64";
      hash = "sha256-e6utZ5avj36jGYvZYzqm8szmq5fF7GjC/eDnTkwqBlI=";
    };
    x86_64-linux = {
      name = "plannotator-linux-x64";
      hash = "sha256-03G3gkKjHWh7rc0ncrc1fjOVZ8h0tE56UDFtHRHSp9E=";
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
