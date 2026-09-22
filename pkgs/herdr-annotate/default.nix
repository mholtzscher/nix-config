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
  runtimeVersion = "0.1.0";
  runtimeAssets = {
    aarch64-darwin = {
      asset = "herdr-annotate-aarch64-apple-darwin";
      hash = "sha256-IjQ5Khzt9LCwVhtMpU2nWqUTnfKW29Tlk3HPf6IB+rc=";
    };
    x86_64-darwin = {
      asset = "herdr-annotate-x86_64-apple-darwin";
      hash = "sha256-kcrRYkRacpGdthjRZCrJwAX0ZRPtxJeGYrhmfIz1UHw=";
    };
    aarch64-linux = {
      asset = "herdr-annotate-aarch64-unknown-linux-gnu";
      hash = "sha256-qh3xiNQ+/XaJPKpfjDuJtZv/57HcPCHLkJcjiHk4IuY=";
    };
    x86_64-linux = {
      asset = "herdr-annotate-x86_64-unknown-linux-gnu";
      hash = "sha256-P1cRHCOtcGIWP2FkxWQrdJMJ08xZdDC+He8I3A2r1xI=";
    };
  };
  runtimeAsset =
    runtimeAssets.${stdenv.hostPlatform.system}
      or (throw "herdr-annotate has no native runtime for ${stdenv.hostPlatform.system}");
  runtimeBinary = fetchurl {
    url = "https://github.com/plannotator/herdr-annotate/releases/download/rust-lite-v${runtimeVersion}/${runtimeAsset.asset}";
    inherit (runtimeAsset) hash;
  };

  plannotatorTuiVersion = "0.9.2";
  plannotatorTuiAssets = {
    aarch64-darwin = {
      asset = "plannotator-tui-aarch64-apple-darwin";
      hash = "sha256-eciAG6usXNJXA0A2U2u89Rp7TNjQa0N/HoVxNxRSHrA=";
    };
    x86_64-darwin = {
      asset = "plannotator-tui-x86_64-apple-darwin";
      hash = "sha256-Nu8FZmwGbbfDJ1nI1u6+YiNxF7iHSIGEY/oqz5TvWDQ=";
    };
    aarch64-linux = {
      asset = "plannotator-tui-aarch64-unknown-linux-gnu";
      hash = "sha256-71efY8JLvkdAGb48xcxaW9BUHreTkbGQlX5Qq26g7bM=";
    };
    x86_64-linux = {
      asset = "plannotator-tui-x86_64-unknown-linux-gnu";
      hash = "sha256-h07KuqNeOs5UnVvzxzg/pNEoi6BrNunwTrT0t7VSKaU=";
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
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "plannotator";
    repo = "herdr-annotate";
    rev = "d02b0b42cf1955a3b206959659f1833622f213b8";
    hash = "sha256-ra+iX1QrsaPe0lmbJ+FOxMp2YWP1YsvPUHPoB3HgOqY=";
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
