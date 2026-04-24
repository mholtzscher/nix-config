{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.19.1";

  assets = {
    aarch64-darwin = {
      name = "plannotator-darwin-arm64";
      hash = "sha256-H2ebrkAC9pQ9gGT4k5KMcikhtme+BdLsTilrP2v8TZ8=";
    };
    x86_64-linux = {
      name = "plannotator-linux-x64";
      hash = "sha256-0bRPmD9lzKjdkNOZQNo4tJD59xAx0BVCQnOo8hVnbkg=";
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
