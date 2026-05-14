#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/update-zitree.sh <commit|latest> [--validate]

Clones Brobicheau/zitree, builds the release WASI plugin, vendors the built
WASM at pkgs/zitree/zitree.wasm, and records the upstream revision in
pkgs/zitree/source.json.

This intentionally keeps Home Manager from compiling the Rust plugin during
normal Nix builds (notably slow on Darwin).
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

requested_rev="$1"
validate=false

if [[ $# -eq 2 ]]; then
  case "$2" in
    --validate) validate=true ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
fi

for command in curl git jq nix; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
wasm_file="$repo_root/pkgs/zitree/zitree.wasm"
metadata_file="$repo_root/pkgs/zitree/source.json"

if [[ "$requested_rev" == "latest" ]]; then
  commit_json=$(curl --fail --silent --show-error --location \
    "https://api.github.com/repos/Brobicheau/zitree/commits/main")
else
  commit_json=$(curl --fail --silent --show-error --location \
    "https://api.github.com/repos/Brobicheau/zitree/commits/$requested_rev")
fi

new_rev=$(jq -r '.sha' <<<"$commit_json")
if [[ -z "$new_rev" || "$new_rev" == "null" ]]; then
  echo "Could not resolve zitree commit: $requested_rev" >&2
  exit 1
fi

commit_date=$(jq -r '.commit.committer.date // .commit.author.date' <<<"$commit_json" | cut -dT -f1)
if [[ -z "$commit_date" || "$commit_date" == "null" ]]; then
  echo "Could not determine commit date for $new_rev" >&2
  exit 1
fi
new_version="unstable-$commit_date"

old_version="unknown"
old_rev="unknown"
if [[ -f "$metadata_file" ]]; then
  old_version=$(jq -r '.version // "unknown"' "$metadata_file")
  old_rev=$(jq -r '.rev // "unknown"' "$metadata_file")
fi

tmpdir=$(mktemp -d)
backup_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir" "$backup_dir"
}
trap cleanup EXIT

[[ -f "$wasm_file" ]] && cp "$wasm_file" "$backup_dir/zitree.wasm"
[[ -f "$metadata_file" ]] && cp "$metadata_file" "$backup_dir/source.json"
restore_on_error() {
  if [[ -f "$backup_dir/zitree.wasm" ]]; then
    rm -f "$wasm_file"
    install -Dm644 "$backup_dir/zitree.wasm" "$wasm_file"
  else
    rm -f "$wasm_file"
  fi

  if [[ -f "$backup_dir/source.json" ]]; then
    rm -f "$metadata_file"
    install -Dm644 "$backup_dir/source.json" "$metadata_file"
  else
    rm -f "$metadata_file"
  fi
}
trap restore_on_error ERR

echo "→ Cloning Brobicheau/zitree at $new_rev"
git clone --quiet https://github.com/Brobicheau/zitree "$tmpdir/zitree"
git -C "$tmpdir/zitree" checkout --quiet "$new_rev"

cat >"$tmpdir/build-zitree.nix" <<NIX
let
  flake = builtins.getFlake "$repo_root";
  pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
in
pkgs.pkgsCross.wasi32.rustPlatform.buildRustPackage {
  pname = "zitree";
  version = "update-script";
  src = ./zitree;

  cargoLock.lockFile = ./zitree/Cargo.lock;

  env.RUSTFLAGS = "-C linker=wasm-ld";
  nativeBuildInputs = [ pkgs.pkgsCross.wasi32.lld ];

  cargoBuildFlags = [ "--target=wasm32-wasip1" ];
  doCheck = false;

  installPhase = ''
    runHook preInstall

    if [[ -f target/wasm32-wasip1/release/treemin.wasm ]]; then
      install -Dm644 target/wasm32-wasip1/release/treemin.wasm \
        \$out/zitree.wasm
    else
      install -Dm644 target/wasm32-wasip1/release/zitree.wasm \
        \$out/zitree.wasm
    fi

    runHook postInstall
  '';
}
NIX

echo "→ Building release WASM with Nix"
built_out=$(cd "$tmpdir" && nix build --no-link --print-out-paths --impure --expr 'import ./build-zitree.nix')
rm -f "$wasm_file"
install -Dm644 "$built_out/zitree.wasm" "$wasm_file"
jq --null-input \
  --arg version "$new_version" \
  --arg rev "$new_rev" \
  '{version: $version, rev: $rev}' >"$metadata_file"

trap - ERR

echo "Updated zitree: $old_version ($old_rev) -> $new_version ($new_rev)"
echo "Vendored WASM: $wasm_file ($(du -h "$wasm_file" | cut -f1))"
echo "Metadata: $metadata_file"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
