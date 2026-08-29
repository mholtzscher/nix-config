{
  autoPatchelfHook,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
}:

let
  plannotatorTuiVersion = "0.3.1";
  plannotatorTuiAssets = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-qisoPe48XgkN7QLi36TVPIxP4NG42dcC7Ek29e/v8Jw=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-cKnWHmjrE9+Mi8YYPuMosOYja2SaRMhHZv182YMjBKE=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-03FgV+ghy+pDH8+e/DL8aSTohOaFq6nJjRdXU8oH8rI=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-xktsrKGEfBWa8NmhiBoRX13mifac51JZXJnqaag5w+A=";
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
    rev = "fb93a1318f960792452cef6cde72a2c4f4591241";
    hash = "sha256-1/coPKNlvCbqaEMW+y214wvn4fgl8TdGyUl6BpqXuPw=";
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
