{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-navigator";
  version = "0.3.5";

  src = fetchFromGitHub {
    owner = "thanhdat77";
    repo = "herdr-navigator";
    rev = "v${version}";
    hash = "sha256-TOAURrMM2UnFaVBFC+ElRaFqYZVx3GtpAx3PuRlc5Nc=";
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
