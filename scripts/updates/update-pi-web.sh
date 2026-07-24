#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/updates/update-pi-web.sh <version|latest> [--validate]

Updates pkgs/pi-web/default.nix with the requested GitHub release and
recomputes both the source and npm dependency hashes.
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

requested_version="$1"
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
package_file="$repo_root/pkgs/pi-web/default.nix"

if [[ ! -f "$package_file" ]]; then
  echo "Could not find package file: $package_file" >&2
  echo "Run this script from inside the nix-config repository." >&2
  exit 1
fi

if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/jmfederico/pi-web/releases/latest"
else
  version_without_v="${requested_version#v}"
  release_url="https://api.github.com/repos/jmfederico/pi-web/releases/tags/v${version_without_v}"
fi

release_json=$(curl --fail --silent --show-error --location "$release_url")
tag_name=$(jq -r '.tag_name // empty' <<<"$release_json")

if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
  echo "Could not determine release tag from $release_url" >&2
  exit 1
fi

new_version="${tag_name#v}"
old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")
archive_url="https://github.com/jmfederico/pi-web/archive/refs/tags/v${new_version}.tar.gz"

echo "-> Fetching source archive for v${new_version}..."
unpacked_hash=$(nix-prefetch-url --unpack "$archive_url" 2>/dev/null)
source_hash=$(nix hash convert --hash-algo sha256 --to sri "sha256:${unpacked_hash}")

backup=$(mktemp)
cp "$package_file" "$backup"
restore_on_error() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    cp "$backup" "$package_file"
    echo "Update failed; restored $package_file" >&2
  fi
  rm -f "$backup"
  exit "$status"
}
trap restore_on_error EXIT

NEW_VERSION="$new_version" SOURCE_HASH="$source_hash" perl -0pi -e '
  s/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/;
  s/(src = fetchFromGitHub \{.*?hash = ")sha256-[^"]+(";)/$1$ENV{SOURCE_HASH}$2/s;
  s/npmDepsHash = "sha256-[^"]+";/npmDepsHash = lib.fakeHash;/;
' "$package_file"

build_expression="let pkgs = import <nixpkgs> {}; in pkgs.callPackage ${package_file} {}"
echo "-> Computing npm dependency hash..."
set +e
build_output=$(nix build --no-link --impure --expr "$build_expression" 2>&1)
build_status=$?
set -e

npm_hash=$(perl -ne 'print "$1\n" and exit if /got:\s+(sha256-[A-Za-z0-9+\/=]+)/' <<<"$build_output")
if [[ $build_status -eq 0 || -z "$npm_hash" ]]; then
  echo "$build_output" >&2
  echo "Could not determine npmDepsHash from the Nix build." >&2
  exit 1
fi

NPM_HASH="$npm_hash" perl -0pi -e \
  's/npmDepsHash = lib\.fakeHash;/npmDepsHash = "$ENV{NPM_HASH}";/' \
  "$package_file"

nixfmt "$package_file"

echo "-> Verifying PI WEB package build..."
nix build --no-link --impure --expr "$build_expression"

echo "Updated pi-web: $old_version -> $new_version"
echo "Source hash: $source_hash"
echo "npm dependencies: $npm_hash"
echo "Updated files:"
echo "  $package_file"

if [[ "$validate" == true ]]; then
  NH_FLAKE="${NH_FLAKE:-$repo_root}" "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
