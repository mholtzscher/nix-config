{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.11.1";

  assets = {
    aarch64-darwin = {
      assetName = "hunkdiff-darwin-arm64";
      hash = "sha256-TjSrDxHjYXasXEr+O0Nid9PcJRvZIbRK/lP7DrGHtZo=";
    };
    x86_64-darwin = {
      assetName = "hunkdiff-darwin-x64";
      hash = "sha256-dq8D7a6s0MUIATq2tgMi0VYIp00qWqLNddiUlIUcazo=";
    };
    aarch64-linux = {
      assetName = "hunkdiff-linux-arm64";
      hash = "sha256-vFzAW+6fXj6kNWm7V7Oj46F8xfjLMssrWti158uQ8ec=";
    };
    x86_64-linux = {
      assetName = "hunkdiff-linux-x64";
      hash = "sha256-XQkhUXxA9Vsd1ILgyo3cRqrOTfYNgVSUyiY9ZnQYchQ=";
    };
  };

  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "hunk is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "hunk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/modem-dev/hunk/releases/download/v${version}/${asset.assetName}.tar.gz";
    inherit (asset) hash;
  };

  sourceRoot = asset.assetName;

  installPhase = ''
    runHook preInstall

    install -Dm755 hunk "$out/bin/hunk"

    runHook postInstall
  '';

  meta = {
    description = "A review-first terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = builtins.attrNames assets;
  };
}
