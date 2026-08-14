{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-navigator";
  version = "0.3.6";

  src = fetchFromGitHub {
    owner = "thanhdat77";
    repo = "herdr-navigator";
    rev = "v${version}";
    hash = "sha256-+xtBu4m2YenFH+W3Sv7atDvcsgChS5mKXgVgKomM768=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  # Two path-matching tests fail in the macOS Nix sandbox.
  doCheck = false;

  postInstall = ''
    cp herdr-plugin.toml "$out/herdr-plugin.toml"
    substituteInPlace "$out/herdr-plugin.toml" \
      --replace-fail './target/release/herdr-navigator' './bin/herdr-navigator'
  '';

  meta = {
    description = "Jump to anything in Herdr from one fuzzy navigator";
    homepage = "https://github.com/thanhdat77/herdr-navigator";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "herdr-navigator";
  };
}
