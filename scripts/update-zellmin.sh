#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/update-zellmin.sh <commit|latest> [--validate]

Clones Brobicheau/zellmin, builds the release WASI plugins, vendors the built
WASM files at pkgs/treemin/treemin.wasm and pkgs/seshmin/seshmin.wasm, and
records the upstream revision in each plugin's source.json.

This intentionally keeps Home Manager from compiling the Rust plugins during
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
    *) usage >&2; exit 2 ;;
  esac
fi

for command in curl git jq nix; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
treemin_wasm="$repo_root/pkgs/treemin/treemin.wasm"
seshmin_wasm="$repo_root/pkgs/seshmin/seshmin.wasm"
treemin_metadata="$repo_root/pkgs/treemin/source.json"
seshmin_metadata="$repo_root/pkgs/seshmin/source.json"

if [[ "$requested_rev" == "latest" ]]; then
  commit_json=$(curl --fail --silent --show-error --location \
    "https://api.github.com/repos/Brobicheau/zellmin/commits/main")
else
  commit_json=$(curl --fail --silent --show-error --location \
    "https://api.github.com/repos/Brobicheau/zellmin/commits/$requested_rev")
fi

new_rev=$(jq -r '.sha' <<<"$commit_json")
if [[ -z "$new_rev" || "$new_rev" == "null" ]]; then
  echo "Could not resolve zellmin commit: $requested_rev" >&2
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
if [[ -f "$treemin_metadata" ]]; then
  old_version=$(jq -r '.version // "unknown"' "$treemin_metadata")
  old_rev=$(jq -r '.rev // "unknown"' "$treemin_metadata")
fi

tmpdir=$(mktemp -d)
backup_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir" "$backup_dir"
}
trap cleanup EXIT

mkdir -p "$backup_dir/treemin" "$backup_dir/seshmin"
[[ -f "$treemin_wasm" ]] && cp "$treemin_wasm" "$backup_dir/treemin/treemin.wasm"
[[ -f "$seshmin_wasm" ]] && cp "$seshmin_wasm" "$backup_dir/seshmin/seshmin.wasm"
[[ -f "$treemin_metadata" ]] && cp "$treemin_metadata" "$backup_dir/treemin/source.json"
[[ -f "$seshmin_metadata" ]] && cp "$seshmin_metadata" "$backup_dir/seshmin/source.json"
restore_file() {
  local backup="$1"
  local target="$2"
  if [[ -f "$backup" ]]; then
    rm -f "$target"
    install -Dm644 "$backup" "$target"
  else
    rm -f "$target"
  fi
}
restore_on_error() {
  restore_file "$backup_dir/treemin/treemin.wasm" "$treemin_wasm"
  restore_file "$backup_dir/seshmin/seshmin.wasm" "$seshmin_wasm"
  restore_file "$backup_dir/treemin/source.json" "$treemin_metadata"
  restore_file "$backup_dir/seshmin/source.json" "$seshmin_metadata"
}
trap restore_on_error ERR

echo "→ Cloning Brobicheau/zellmin at $new_rev"
git clone --quiet https://github.com/Brobicheau/zellmin "$tmpdir/zellmin"
git -C "$tmpdir/zellmin" checkout --quiet "$new_rev"

cat >"$tmpdir/build-zellmin.nix" <<NIX
let
  flake = builtins.getFlake "$repo_root";
  pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
in
pkgs.pkgsCross.wasi32.rustPlatform.buildRustPackage {
  pname = "zellmin";
  version = "update-script";
  src = ./zellmin;

  cargoLock.lockFile = ./zellmin/Cargo.lock;

  env.RUSTFLAGS = "-C linker=wasm-ld";
  nativeBuildInputs = [ pkgs.pkgsCross.wasi32.lld ];

  cargoBuildFlags = [ "--target=wasm32-wasip1" "--workspace" ];
  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm644 target/wasm32-wasip1/release/treemin.wasm \
      \$out/treemin.wasm
    install -Dm644 target/wasm32-wasip1/release/seshmin.wasm \
      \$out/seshmin.wasm
    runHook postInstall
  '';
}
NIX

echo "→ Building release WASM plugins with Nix"
built_out=$(cd "$tmpdir" && nix build --no-link --print-out-paths --impure --expr 'import ./build-zellmin.nix')

rm -f "$treemin_wasm" "$seshmin_wasm"
install -Dm644 "$built_out/treemin.wasm" "$treemin_wasm"
install -Dm644 "$built_out/seshmin.wasm" "$seshmin_wasm"

for metadata_file in "$treemin_metadata" "$seshmin_metadata"; do
  jq --null-input \
    --arg version "$new_version" \
    --arg rev "$new_rev" \
    --arg repo "Brobicheau/zellmin" \
    '{version: $version, rev: $rev, repo: $repo}' >"$metadata_file"
done

trap - ERR

echo "Updated zellmin: $old_version ($old_rev) -> $new_version ($new_rev)"
echo "Vendored treemin WASM: $treemin_wasm ($(du -h "$treemin_wasm" | cut -f1))"
echo "Vendored seshmin WASM: $seshmin_wasm ($(du -h "$seshmin_wasm" | cut -f1))"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
