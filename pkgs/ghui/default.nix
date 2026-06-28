{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.9.0";

  assets = {
    aarch64-darwin = {
      name = "ghui-darwin-arm64.tar.gz";
      hash = "sha256-DwWXOVaW90xmuvb/149xh9zc69InKnq2nHRPJCHKQMg=";
    };
    x86_64-darwin = {
      name = "ghui-darwin-x64.tar.gz";
      hash = "sha256-AeqcdyqJJcKnycVnbi5vpPN7WA5eZMDlBxAdpYvkZTE=";
    };
    aarch64-linux = {
      name = "ghui-linux-arm64.tar.gz";
      hash = "sha256-mTdQpDmHJvFpPqHJqKKdVgUpA3qm2sQ8Xndag7rGfKU=";
    };
    x86_64-linux = {
      name = "ghui-linux-x64.tar.gz";
      hash = "sha256-bKBZkPvf61/q+7C6RtoAWQuywiNmo5G6sLfKB+OdFVA=";
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
