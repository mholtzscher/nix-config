{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  autoAddDriverRunpath,
  openssl,
  cudaPackages_12_8,
}:

let
  # Pinned to the release Bonsai-demo's download_binaries.sh uses.
  # Bump together with scripts/download-binaries expectations upstream.
  # Stock nixpkgs llama-cpp cannot run Bonsai 2 (unknown PQ2_0/PTQ1_0 types,
  # silent garbage on Q2_0) — this fork has the ternary hybrid-attention kernels.
  releaseTag = "prism-b10709-9a9394a";
in
stdenv.mkDerivation {
  pname = "bonsai-llama-cpp";
  version = "b10709-9a9394a";

  src = fetchurl {
    url = "https://github.com/PrismML-Eng/llama.cpp/releases/download/${releaseTag}/llama-${releaseTag}-bin-linux-cuda-12.8-x64.tar.gz";
    hash = "sha256-iuxn6wI7JRcSx+ZJDzZ7VnG/WH7O0UNqm4X0qQw7fT0=";
  };

  sourceRoot = ".";

  # libcuda.so.1 ships with the host NVIDIA driver (/run/opengl-driver),
  # not the Nix store. Ignore it at build time; autoAddDriverRunpath
  # wires the driver path in so it resolves at runtime.
  autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];

  nativeBuildInputs = [
    autoPatchelfHook
    autoAddDriverRunpath
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    openssl
    cudaPackages_12_8.cuda_cudart
    cudaPackages_12_8.libcublas
  ];

  installPhase = ''
    runHook preInstall

    dir="llama-${releaseTag}"
    mkdir -p "$out/bin" "$out/lib" "$out/share/doc/bonsai-llama-cpp"

    for f in "$dir"/llama-*; do
      if [ -f "$f" ] && [ -x "$f" ]; then
        install -Dm755 "$f" "$out/bin/$(basename "$f")"
      fi
    done

    for f in "$dir"/lib*.so*; do
      [ -e "$f" ] && cp -P "$f" "$out/lib/"
    done

    install -Dm644 "$dir/LICENSE" "$out/share/doc/bonsai-llama-cpp/LICENSE"

    runHook postInstall
  '';

  meta = with lib; {
    description = "PrismML fork of llama.cpp (CUDA 12.8) with ternary kernels for Bonsai 2 27B";
    homepage = "https://github.com/PrismML-Eng/llama.cpp";
    license = licenses.mit;
    mainProgram = "llama-server";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
