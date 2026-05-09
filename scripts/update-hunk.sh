#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/update-hunk.sh <version|latest> [--validate]

Examples:
  scripts/update-hunk.sh latest
  scripts/update-hunk.sh 0.10.0
  scripts/update-hunk.sh v0.10.0 --validate

Updates:
  pkgs/hunk/default.nix
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

for command in curl jq nix; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/hunk/default.nix"

if [[ ! -f "$package_file" ]]; then
  echo "Run this script from inside the nix-config repository." >&2
  exit 1
fi

if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/modem-dev/hunk/releases/latest"
else
  version_without_v="${requested_version#v}"
  release_url="https://api.github.com/repos/modem-dev/hunk/releases/tags/v${version_without_v}"
fi

release_json=$(curl --fail --silent --show-error --location "$release_url")
tag_name=$(jq -r '.tag_name // empty' <<<"$release_json")

if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
  echo "Could not determine release tag from $release_url" >&2
  exit 1
fi

new_version="${tag_name#v}"
old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")

asset_digest() {
  local asset_name="$1"
  jq -r --arg name "$asset_name" '
    .assets[]
    | select(.name == $name)
    | .digest // empty
  ' <<<"$release_json"
}

digest_to_sri() {
  local digest="$1"
  local hex="${digest#sha256:}"

  if [[ "$digest" == "$hex" || -z "$hex" ]]; then
    echo "Invalid asset digest: $digest" >&2
    exit 1
  fi

  nix hash convert --hash-algo sha256 --to sri "$hex"
}

platform_assets=(
  "aarch64-darwin:hunkdiff-darwin-arm64"
  "x86_64-darwin:hunkdiff-darwin-x64"
  "aarch64-linux:hunkdiff-linux-arm64"
  "x86_64-linux:hunkdiff-linux-x64"
)
hash_updates=()

for platform_asset in "${platform_assets[@]}"; do
  IFS=: read -r platform asset_name <<<"$platform_asset"
  digest=$(asset_digest "${asset_name}.tar.gz")

  if [[ -z "$digest" ]]; then
    echo "Release $tag_name is missing required CLI asset: ${asset_name}.tar.gz" >&2
    exit 1
  fi

  hash=$(digest_to_sri "$digest")
  hash_updates+=("$platform:$asset_name:$hash")
done

NEW_VERSION="$new_version" perl -0pi -e 's/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/' "$package_file"

for hash_update in "${hash_updates[@]}"; do
  IFS=: read -r platform asset_name hash <<<"$hash_update"
  PLATFORM="$platform" ASSET_NAME="$asset_name" HASH="$hash" perl -0pi -e 's/(\Q$ENV{PLATFORM}\E = \{\n\s+assetName = "\Q$ENV{ASSET_NAME}\E";\n\s+hash = ")sha256-[^"]+(";)/$1$ENV{HASH}$2/' "$package_file"
done

echo "Updated hunk: $old_version -> $new_version"
echo "Updated files:"
echo "  $package_file"
echo "Hashes:"
for hash_update in "${hash_updates[@]}"; do
  IFS=: read -r _ asset_name hash <<<"$hash_update"
  echo "  ${asset_name}.tar.gz: $hash"
done

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
