{
  autoPatchelfHook,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
}:

let
  plannotatorTuiVersion = "0.3.0";
  plannotatorTuiAssets = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-4NdTnLv9I1RERCwj53FqHgmkq1lkxUe5uS6qoVTukPg=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-3Z+uH5ZJtk2azNc5qMYDL7i+dFx0np2yJZbgfTZ8xJ4=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-3xs5+yzUpCPqMGI26KUQc3ZSd/KgvUxCGcCu7aoFcnI=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-QdfI+OSxDj+0085WnNPd7Ho2vW3x+X285NAneru6D9s=";
    };
  };
  plannotatorTuiAsset =
    plannotatorTuiAssets.${stdenv.hostPlatform.system}
      or (throw "herdr-annotate is not packaged for ${stdenv.hostPlatform.system}");
  plannotatorTui = fetchurl {
    url = "https://github.com/plannotator/plannotator-tui/releases/download/v${plannotatorTuiVersion}/plannotator-tui-${plannotatorTuiAsset.target}";
    inherit (plannotatorTuiAsset) hash;
  };
in
stdenv.mkDerivation rec {
  pname = "herdr-annotate";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "plannotator";
    repo = "herdr-annotate";
    rev = "a998f214db9e476885e2c799d8d1477658296d1a";
    hash = "sha256-ZWmr3PxeJq1PzTZuaK8jnZE9cj7n1DjzmLK46vo4Z+Q=";
  };

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r herdr-plugin.toml package.json plannotator-tui.version scripts skills src "$out/"
    install -m755 ${plannotatorTui} "$out/bin/plannotator-tui"
    echo ${lib.escapeShellArg plannotatorTuiVersion} > "$out/bin/plannotator-tui.version"

    runHook postInstall
  '';

  meta = {
    description = "Add comments to copied terminal text in Herdr";
    homepage = "https://github.com/plannotator/herdr-annotate";
    platforms = builtins.attrNames plannotatorTuiAssets;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
}
