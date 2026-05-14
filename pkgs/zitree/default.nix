{
  lib,
  fetchFromGitHub,
  rustPlatform,
  lld,
}:

rustPlatform.buildRustPackage rec {
  pname = "zitree";
  version = "unstable-2026-05-13";

  src = fetchFromGitHub {
    owner = "Brobicheau";
    repo = "zitree";
    rev = "a3cd04073e0409a4b49bfe1007fd1c4b52a7e1e2";
    hash = "sha256-dtQhLUKatmbUJz+EZ7BqkZ1Ii5uGQq2I0qqhcSar/2U=";
  };

  cargoHash = lib.fakeHash;

  env.RUSTFLAGS = "-C linker=wasm-ld";
  nativeBuildInputs = [ lld ];

  cargoBuildFlags = [ "--target=wasm32-wasip1" ];
  doCheck = false;

  installPhase = ''
    runHook preInstall

    install -Dm644 target/wasm32-wasip1/release/zitree.wasm \
      $out/lib/zellij/plugins/zitree.wasm

    runHook postInstall
  '';

  meta = {
    description = "Zellij plugin for creating Git worktrees and switching sessions";
    homepage = "https://github.com/Brobicheau/zitree";
    platforms = lib.platforms.all;
  };
}
