#!/usr/bin/env bash
# Reusable updater for packages fetched from a versioned GitHub source archive.
#
# The sourcing script must set:
#   PKG_NAME    - Directory name under pkgs/
#   GITHUB_REPO - GitHub owner/repository

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: ${0##*/} <version|latest> [--validate]" >&2
  echo "Updates: pkgs/${PKG_NAME:-<pkg>}/default.nix" >&2
  exit 2
fi

requested_version="$1"
validate=false

if [[ $# -eq 2 ]]; then
  case "$2" in
    --validate) validate=true ;;
    *)
      echo "Usage: ${0##*/} <version|latest> [--validate]" >&2
      exit 2
      ;;
  esac
fi

if [[ -z "${PKG_NAME:-}" ]]; then
  echo "Error: PKG_NAME must be set before sourcing common-source.sh" >&2
  exit 1
fi
if [[ -z "${GITHUB_REPO:-}" ]]; then
  echo "Error: GITHUB_REPO must be set before sourcing common-source.sh" >&2
  exit 1
fi

for command in curl jq nix nix-prefetch-url perl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/$PKG_NAME/default.nix"

if [[ ! -f "$package_file" ]]; then
  echo "Could not find package file: $package_file" >&2
  echo "Run this script from inside the nix-config repository." >&2
  exit 1
fi

if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
else
  version_without_v="${requested_version#v}"
  release_url="https://api.github.com/repos/${GITHUB_REPO}/releases/tags/v${version_without_v}"
fi

release_json=$(curl --fail --silent --show-error --location "$release_url")
tag_name=$(jq -r '.tag_name // empty' <<<"$release_json")

if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
  echo "Could not determine release tag from $release_url" >&2
  exit 1
fi

new_version="${tag_name#v}"
old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")
archive_url="https://github.com/${GITHUB_REPO}/archive/refs/tags/${tag_name}.tar.gz"

echo "-> Fetching source archive for ${tag_name}..."
unpacked_hash=$(nix-prefetch-url --unpack "$archive_url" 2>/dev/null)
sri_hash=$(nix hash convert --hash-algo sha256 --to sri "sha256:${unpacked_hash}" 2>/dev/null)

if [[ -z "$sri_hash" ]]; then
  echo "Error: could not compute SRI hash for ${tag_name}" >&2
  exit 1
fi

NEW_VERSION="$new_version" perl -0pi -e \
  's/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/' \
  "$package_file"

SRI_HASH="$sri_hash" perl -0pi -e \
  's/(src = fetchFromGitHub \{.*?hash = ")sha256-[^"]+(";)/$1$ENV{SRI_HASH}$2/s' \
  "$package_file"

if ! grep -Fq "version = \"$new_version\";" "$package_file" ||
  ! grep -Fq "hash = \"$sri_hash\";" "$package_file"; then
  echo "Error: failed to update $package_file" >&2
  exit 1
fi

echo "Updated $PKG_NAME: $old_version -> $new_version"
echo "Hash: $sri_hash"
echo "Updated files:"
echo "  $package_file"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
