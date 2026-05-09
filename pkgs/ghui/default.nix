{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.7.1";

  assets = {
    aarch64-darwin = {
      name = "ghui-darwin-arm64.tar.gz";
      hash = "sha256-KP/GaHFlMB2a4xV0JVf103ZMfnKsK7v8iS+Hqx45pbc=";
    };
    x86_64-darwin = {
      name = "ghui-darwin-x64.tar.gz";
      hash = "sha256-WauY75/Ed90X/nE6MpcpLCNMDB6VIjDxYHTbzxdoehs=";
    };
    aarch64-linux = {
      name = "ghui-linux-arm64.tar.gz";
      hash = "sha256-W4JLchwjOvyFuWBl941Y2tCrKiU+DPt9DM66avGCoXw=";
    };
    x86_64-linux = {
      name = "ghui-linux-x64.tar.gz";
      hash = "sha256-TEqHZGrgLzI6QWkEhBIjo7yoAg/o9+b6rvpXQhhvpYo=";
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
