{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  ffmpeg,
  fontconfig,
  stdenv,
}:
let
  version = "1.2.1";
  targets = {
    aarch64-darwin = "darwin-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-linux = "linux-arm64-gnu";
    x86_64-linux = "linux-x64-gnu";
  };
  hashes = {
    aarch64-darwin = "sha256-EYFl9wHL0nDA+WEHyw7HNKS4r97OL21OEcQ56wkIXq0=";
    x86_64-darwin = "sha256-GHV20xPXGj0ZYK6tE6qKWelUiH/dlNWRXSQZ4Rr1/oI=";
    aarch64-linux = "sha256-/2SrdXM2aoPCivgXqN4Q0/Th8jNtqBABnCMdeq/M6uc=";
    x86_64-linux = "sha256-BO0hhlOGWH30QJeQsOOX5/JQxgX0J1vlVu1HH5sHQZw=";
  };
  system = stdenvNoCC.hostPlatform.system;
  target = targets.${system} or (throw "terminal-control is not packaged for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "terminal-control";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@kitlangton/terminal-control-${target}/-/terminal-control-${target}-${version}.tgz";
    hash = hashes.${system};
  };

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    fontconfig
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/termctrl "$out/bin/termctrl"
    wrapProgram "$out/bin/termctrl" --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}
    runHook postInstall
  '';

  meta = {
    description = "Control, inspect, test, and capture terminal applications";
    homepage = "https://github.com/anomalyco/terminal-control";
    license = lib.licenses.mit;
    mainProgram = "termctrl";
    platforms = builtins.attrNames targets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
