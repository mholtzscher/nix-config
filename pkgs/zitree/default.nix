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
    rev = "80d1a4c315dcf097b330c2b70a38e176115dc463";
    hash = "sha256-miHoX1D5BOJ3XzraKn644R2uH7FmueOLl5X0ToclAzQ=";
  };

  cargoHash = "sha256-A4iWa7GYkyhxKzqXsXbA1nkBEXIn6Pdn4oZNjBW+eHc=";

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
