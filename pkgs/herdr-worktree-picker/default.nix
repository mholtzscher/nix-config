{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-worktree-picker";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "mholtzscher";
    repo = "herdr-worktree-picker";
    rev = "v${version}";
    hash = "sha256-CFMebU0+VHcWrkWAJDz0aYG/Hs94WRnZN2WdjNADAYU=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  # Upstream's tests are flaky in the Nix sandbox.
  doCheck = false;

  postInstall = ''
    cp herdr-plugin.toml "$out/herdr-plugin.toml"
    substituteInPlace "$out/herdr-plugin.toml" \
      --replace-fail './target/release/herdr-worktree-picker' './bin/herdr-worktree-picker'
  '';

  meta = {
    description = "Create Herdr worktrees from local or remote branches";
    homepage = "https://github.com/mholtzscher/herdr-worktree-picker";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "herdr-worktree-picker";
  };
}
