{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "herdr-worktree-picker";
  version = "0.2.0";

  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;

  postInstall = ''
    cp herdr-plugin.toml "$out/herdr-plugin.toml"
  '';

  meta = {
    description = "Create Herdr worktrees from local or remote branches";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "herdr-worktree-picker";
  };
}
