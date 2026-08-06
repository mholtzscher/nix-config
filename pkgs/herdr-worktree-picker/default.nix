{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-worktree-picker";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "mholtzscher";
    repo = "herdr-worktree-picker";
    rev = "v${version}";
    hash = "sha256-N4Z6XAxDE8UtLIX467V1AN2gIf4Cq2Cg8FzLwW9+h0w=";
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
