{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-worktree-picker";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "mholtzscher";
    repo = "herdr-worktree-picker";
    rev = "v${version}";
    hash = "sha256-ytn8XpoBoZQeB7XIYsxTEPGMN95gf/nQO8GGTAUjy+8=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

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
