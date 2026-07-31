{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-focus-or-tab";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "mholtzscher";
    repo = "herdr-focus-or-tab";
    rev = "v${version}";
    hash = "sha256-eFNf+4J0pWwFQrp5Mk9AlBYULayYsGcMfCdqnDfNzx8=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  postInstall = ''
    cp herdr-plugin.toml "$out/herdr-plugin.toml"
    substituteInPlace "$out/herdr-plugin.toml" \
      --replace-fail './target/release/herdr-focus-or-tab' './bin/herdr-focus-or-tab'
  '';

  meta = {
    description = "Cycle through Herdr panes across tab boundaries";
    homepage = "https://github.com/mholtzscher/herdr-focus-or-tab";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "herdr-focus-or-tab";
  };
}
