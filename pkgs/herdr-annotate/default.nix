{
  autoPatchelfHook,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
}:

# Herdr plugin for annotating terminal selections and reviewing documents.
#
# Three independent version numbers feed this package, all of them read from the pinned source
# tree by scripts/updates/update-herdr-annotate.sh:
#
#   herdr-plugin.toml         its `version` is the plugin version, and therefore this package's
#   herdr-annotate.version    the native runtime, released as tag rust-lite-v<runtimeVersion>
#   plannotator-tui.version   document review, released as tag v<plannotatorTuiVersion>
#
# Upstream has no compile step here: Herdr's build hook runs scripts/fetch-*.sh, which download
# one prebuilt binary per platform. This derivation pre-stages those same release assets and
# stamps bin/*.version, so the hooks short-circuit instead of downloading into the read-only
# store. Everything else in the plugin root (manifest, scripts, skills) comes from src.
let
  runtimeVersion = "0.2.0";
  runtimeAssets = {
    aarch64-darwin = {
      asset = "herdr-annotate-aarch64-apple-darwin";
      hash = "sha256-WpxT03fNh+ZN4BueQ8hJBFP2q4GhExHTQKS/8HDqQwg=";
    };
    x86_64-darwin = {
      asset = "herdr-annotate-x86_64-apple-darwin";
      hash = "sha256-GUMf4vGkC98SL7b9wipo/1/5VcxOjJw7iz3qJONA/+0=";
    };
    aarch64-linux = {
      asset = "herdr-annotate-aarch64-unknown-linux-gnu";
      hash = "sha256-xNOA7VpwzXtDZCgsPXApCkgal5NQYrvlxnJXmRxpH28=";
    };
    x86_64-linux = {
      asset = "herdr-annotate-x86_64-unknown-linux-gnu";
      hash = "sha256-o+9OcnhLuoz3nlgtYCHKNPDWAPFw2jCVvMYKh7G8uUI=";
    };
  };
  runtimeAsset =
    runtimeAssets.${stdenv.hostPlatform.system}
      or (throw "herdr-annotate has no native runtime for ${stdenv.hostPlatform.system}");
  runtimeBinary = fetchurl {
    url = "https://github.com/plannotator/herdr-annotate/releases/download/rust-lite-v${runtimeVersion}/${runtimeAsset.asset}";
    inherit (runtimeAsset) hash;
  };

  plannotatorTuiVersion = "0.9.4";
  plannotatorTuiAssets = {
    aarch64-darwin = {
      asset = "plannotator-tui-aarch64-apple-darwin";
      hash = "sha256-qdpJ3WpE00lP7Q6DZsoymW7N9A4CcfztQQzsPIg5F10=";
    };
    x86_64-darwin = {
      asset = "plannotator-tui-x86_64-apple-darwin";
      hash = "sha256-XRloPW+QpCSf+vOmp+0LoTJaE2p5XHsRqLofsW/o0U8=";
    };
    aarch64-linux = {
      asset = "plannotator-tui-aarch64-unknown-linux-gnu";
      hash = "sha256-45B3qsLh537XmNJZD4Rc+ZjkVvoqIS/nyuLiX+v2III=";
    };
    x86_64-linux = {
      asset = "plannotator-tui-x86_64-unknown-linux-gnu";
      hash = "sha256-1U3GA8lfcQZ3vBPr5rJLLm6xDOdhV3r4qVoFAChit00=";
    };
  };
  plannotatorTuiAsset =
    plannotatorTuiAssets.${stdenv.hostPlatform.system}
      or (throw "plannotator-tui has no build for ${stdenv.hostPlatform.system}");
  plannotatorTuiBinary = fetchurl {
    url = "https://github.com/plannotator/plannotator-tui/releases/download/v${plannotatorTuiVersion}/${plannotatorTuiAsset.asset}";
    inherit (plannotatorTuiAsset) hash;
  };
in
stdenv.mkDerivation rec {
  pname = "herdr-annotate";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "plannotator";
    repo = "herdr-annotate";
    rev = "cbba4732229191347ff5128e3da71f64474a6a49";
    hash = "sha256-CDh80DN7xWtEAPTNu80T+PGBjUAHt66HSWgNVx87tXU=";
  };

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r herdr-plugin.toml LICENSE README.md scripts skills "$out/"

    # Herdr runs the plugin root's binaries as ./bin/<name>.exe, on every platform.
    install -m755 ${runtimeBinary} "$out/bin/herdr-annotate.exe"
    install -m755 ${plannotatorTuiBinary} "$out/bin/plannotator-tui.exe"

    # The bundled plannotator-tui skill tells agents to run `plannotator-tui` from PATH.
    ln -s plannotator-tui.exe "$out/bin/plannotator-tui"

    # scripts/fetch-*.sh compare bin/<name>.version against the root *.version file and only
    # download when they differ, so both are written from the pins above and cannot drift.
    echo ${lib.escapeShellArg runtimeVersion} > "$out/herdr-annotate.version"
    echo ${lib.escapeShellArg runtimeVersion} > "$out/bin/herdr-annotate.version"
    echo ${lib.escapeShellArg plannotatorTuiVersion} > "$out/plannotator-tui.version"
    echo ${lib.escapeShellArg plannotatorTuiVersion} > "$out/bin/plannotator-tui.version"

    runHook postInstall
  '';

  meta = {
    description = "Add comments to copied terminal text in Herdr";
    homepage = "https://github.com/plannotator/herdr-annotate";
    license = lib.licenses.mit;
    platforms = builtins.attrNames runtimeAssets;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
}
