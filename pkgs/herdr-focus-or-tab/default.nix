{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-focus-or-tab";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "mholtzscher";
    repo = "herdr-focus-or-tab";
    rev = "v${version}";
    hash = "sha256-gUUI77RaRDN5vNyRT7LyVXlSkLbvQa/68kOh/B8MzOQ=";
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
