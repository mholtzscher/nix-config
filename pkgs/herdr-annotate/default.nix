{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "herdr-annotate";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "plannotator";
    repo = "herdr-annotate";
    rev = "a998f214db9e476885e2c799d8d1477658296d1a";
    hash = "sha256-ZWmr3PxeJq1PzTZuaK8jnZE9cj7n1DjzmLK46vo4Z+Q=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r herdr-plugin.toml package.json src "$out/"

    runHook postInstall
  '';

  meta = {
    description = "Add comments to copied terminal text in Herdr";
    homepage = "https://github.com/plannotator/herdr-annotate";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
