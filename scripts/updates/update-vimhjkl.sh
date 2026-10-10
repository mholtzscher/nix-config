#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/updates/update-vimhjkl.sh <version|latest> [--validate]

Updates pkgs/vimhjkl/default.nix with the given version tag and recomputes
the source hash.
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

for command in curl jq nix nix-prefetch-url; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/vimhjkl/default.nix"

if [[ ! -f "$package_file" ]]; then
  echo "Could not find package file: $package_file" >&2
  echo "Run this script from inside the nix-config repository." >&2
  exit 1
fi

# Fetch release info from GitHub
if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/S-Sigdel/vimhjkl/releases/latest"
else
  version_without_v="${requested_version#v}"
  release_url="https://api.github.com/repos/S-Sigdel/vimhjkl/releases/tags/v${version_without_v}"
fi

release_json=$(curl --fail --silent --show-error --location "$release_url")
tag_name=$(jq -r '.tag_name // empty' <<<"$release_json")

if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
  echo "Could not determine release tag from $release_url" >&2
  exit 1
fi

new_version="${tag_name#v}"
old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")

echo "-> Fetching source archive for v${new_version}..."
archive_url="https://github.com/S-Sigdel/vimhjkl/archive/refs/tags/v${new_version}.tar.gz"

# nix-prefetch-url --unpack returns the hash in nix base32 encoding
unpacked_hash=$(nix-prefetch-url --unpack "$archive_url" 2>/dev/null)

# Convert base32 to SRI format (sha256-<base64>) using nix hash convert.
# nix hash convert accepts the input hash prefixed with "sha256:" (colon).
sri_hash=$(nix hash convert --hash-algo sha256 --to sri "sha256:${unpacked_hash}" 2>/dev/null)

if [[ -z "$sri_hash" ]]; then
  echo "Error: could not compute SRI hash for v${new_version}" >&2
  exit 1
fi

# Update version in package file
NEW_VERSION="$new_version" perl -0pi -e 's/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/' "$package_file"

# Update hash in package file
SRI_HASH="$sri_hash" perl -0pi -e 's/hash = "sha256-[^"]+";/hash = "$ENV{SRI_HASH}";/' "$package_file"

echo "Updated vimhjkl: $old_version -> $new_version"
echo "Hash: $sri_hash"
echo "Updated files:"
echo "  $package_file"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
