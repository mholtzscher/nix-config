#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/update-zitree.sh <commit|latest> [--validate]

Updates pkgs/zitree/default.nix to a GitHub commit and refreshes both the
source hash and Cargo vendor hash.
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

for command in curl jq nix nix-prefetch-url perl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/zitree/default.nix"

if [[ ! -f "$package_file" ]]; then
  echo "Could not find package file: $package_file" >&2
  exit 1
fi

if [[ "$requested_rev" == "latest" ]]; then
  commit_json=$(curl --fail --silent --show-error --location \
    "https://api.github.com/repos/Brobicheau/zitree/commits/main")
  new_rev=$(jq -r '.sha' <<<"$commit_json")
else
  new_rev="$requested_rev"
  commit_json=$(curl --fail --silent --show-error --location \
    "https://api.github.com/repos/Brobicheau/zitree/commits/$new_rev")
  new_rev=$(jq -r '.sha' <<<"$commit_json")
fi

if [[ -z "$new_rev" || "$new_rev" == "null" ]]; then
  echo "Could not resolve zitree commit: $requested_rev" >&2
  exit 1
fi

commit_date=$(jq -r '.commit.committer.date // .commit.author.date' <<<"$commit_json" | cut -dT -f1)
if [[ -z "$commit_date" || "$commit_date" == "null" ]]; then
  echo "Could not determine commit date for $new_rev" >&2
  exit 1
fi

old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")
old_rev=$(perl -ne 'print "$1\n" and exit if /rev = "([^"]+)";/' "$package_file")
new_version="unstable-$commit_date"

tarball_url="https://github.com/Brobicheau/zitree/archive/$new_rev.tar.gz"
echo "→ Prefetching source $new_rev"
src_hash_base32=$(nix-prefetch-url --unpack "$tarball_url" 2>/dev/null | tail -n1)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$src_hash_base32")

backup=$(mktemp)
cp "$package_file" "$backup"
restore_on_error() {
  cp "$backup" "$package_file"
  rm -f "$backup"
}
trap restore_on_error ERR

NEW_VERSION="$new_version" NEW_REV="$new_rev" SRC_HASH="$src_hash" perl -0pi -e '
  s/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/;
  s/rev = "[^"]+";/rev = "$ENV{NEW_REV}";/;
  s/(src = fetchFromGitHub \{.*?hash = ")sha256-[^"]+";/$1$ENV{SRC_HASH}";/s;
  s/cargoHash = "sha256-[^"]+";/cargoHash = lib.fakeHash;/;
' "$package_file"

build_expr='let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; }; in pkgs.pkgsCross.wasi32.callPackage ./pkgs/zitree { }'

echo "→ Calculating Cargo vendor hash"
set +e
build_output=$(cd "$repo_root" && nix build --no-link --impure --expr "$build_expr" 2>&1)
build_status=$?
set -e

cargo_hash=$(perl -ne 'print "$1\n" if /got:\s+(sha256-[A-Za-z0-9+\/=]+)/' <<<"$build_output" | tail -n1)
if [[ -z "$cargo_hash" ]]; then
  echo "$build_output" >&2
  echo "Could not determine Cargo vendor hash" >&2
  exit "$build_status"
fi

CARGO_HASH="$cargo_hash" perl -0pi -e \
  's/cargoHash = lib\.fakeHash;/cargoHash = "$ENV{CARGO_HASH}";/' \
  "$package_file"

trap - ERR
rm -f "$backup"

echo "Updated zitree: $old_version ($old_rev) -> $new_version ($new_rev)"
echo "Hashes:"
echo "  source: $src_hash"
echo "  cargo:  $cargo_hash"
echo "Updated files:"
echo "  $package_file"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
