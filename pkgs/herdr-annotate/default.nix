{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "herdr-annotate";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "plannotator";
    repo = "herdr-annotate";
    rev = "e5cf412c842c2ddab33494bf2b63484d10a8d33f";
    hash = "sha256-8I7VhJxAEl+rPJhWWCzDArSb8X6SF8aq7OfoDGzCfoc=";
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
