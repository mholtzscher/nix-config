#!/usr/bin/env bash
# Reusable update script for GitHub release-based packages.
#
# This script is designed to be sourced from thin per-package wrappers
# (see scripts/update-hunk.sh for an example).
#
# The sourcing script must set these variables:
#   PKG_NAME        - Package name (e.g., "hunk")
#   GITHUB_REPO     - GitHub owner/repo (e.g., "modem-dev/hunk")
#   ASSET_KEY       - Key used in the asset attrset ("name" or "assetName")
#   URL_SUFFIX      - Suffix appended to asset name in download URL
#                     (e.g., ".tar.gz" if Nix stores it without extension)
#   PLATFORM_ASSETS - Array of "platform:asset_name" pairs
#
# It may define this function:
#   extra_version_updates() - Called after version/hash updates
#                             Access "$new_version" for the new version string.

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: ${0##*/} <version|latest> [--validate]" >&2
  echo "" >&2
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

# Validate required config variables
if [[ -z "${PKG_NAME:-}" ]]; then echo "Error: PKG_NAME must be set before sourcing update-from-github.sh" >&2; exit 1; fi
if [[ -z "${GITHUB_REPO:-}" ]]; then echo "Error: GITHUB_REPO must be set before sourcing update-from-github.sh" >&2; exit 1; fi
if [[ -z "${ASSET_KEY:-}" ]]; then echo "Error: ASSET_KEY must be set before sourcing update-from-github.sh" >&2; exit 1; fi
if [[ -z "${URL_SUFFIX+x}" ]]; then echo "Error: URL_SUFFIX must be set before sourcing update-from-github.sh" >&2; exit 1; fi
if [[ ${#PLATFORM_ASSETS[@]} -eq 0 ]]; then echo "Error: PLATFORM_ASSETS must be non-empty" >&2; exit 1; fi

for command in curl jq nix perl; do
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

# Fetch release info from GitHub
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

# Helper: get asset digest from GitHub API response
asset_digest() {
  local asset_name="$1"
  jq -r --arg name "$asset_name" '
    .assets[]
    | select(.name == $name)
    | .digest // empty
  ' <<<"$release_json"
}

# Helper: convert hex digest to SRI hash
digest_to_sri() {
  local digest="$1"
  local hex="${digest#sha256:}"

  if [[ "$digest" == "$hex" || -z "$hex" ]]; then
    echo "Invalid asset digest: $digest" >&2
    exit 1
  fi

  nix hash convert --hash-algo sha256 --to sri "$hex"
}

# Process each platform asset
hash_updates=()

for platform_asset in "${PLATFORM_ASSETS[@]}"; do
  IFS=: read -r platform asset_name <<<"$platform_asset"
  # GitHub API asset name includes URL_SUFFIX
  github_asset_name="${asset_name}${URL_SUFFIX}"
  digest=$(asset_digest "$github_asset_name")

  if [[ -z "$digest" ]]; then
    echo "Release $tag_name is missing required asset: $github_asset_name" >&2
    exit 1
  fi

  hash=$(digest_to_sri "$digest")
  hash_updates+=("$platform:$asset_name:$hash")
done

# Update version in package file
NEW_VERSION="$new_version" perl -0pi -e 's/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/' "$package_file"

# Update hashes in package file
for hash_update in "${hash_updates[@]}"; do
  IFS=: read -r platform asset_name hash <<<"$hash_update"
  PLATFORM="$platform" ASSET_KEY="$ASSET_KEY" ASSET_NAME="$asset_name" HASH="$hash" \
    perl -0pi -e '
      s/(\Q$ENV{PLATFORM}\E = \{\n\s+\Q$ENV{ASSET_KEY}\E = "\Q$ENV{ASSET_NAME}\E";\n\s+hash = ")sha256-[^"]+(";)/$1$ENV{HASH}$2/
    ' "$package_file"
done

echo "Updated $PKG_NAME: $old_version -> $new_version"
echo "Updated files:"
echo "  $package_file"

# If the sourcing script defined extra_version_updates, call it
if declare -F extra_version_updates >/dev/null 2>&1; then
  extra_version_updates
fi

echo "Hashes:"
for hash_update in "${hash_updates[@]}"; do
  IFS=: read -r _ asset_name hash <<<"$hash_update"
  echo "  ${asset_name}${URL_SUFFIX}: $hash"
done

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
