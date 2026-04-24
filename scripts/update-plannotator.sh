#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/update-plannotator.sh <version|latest> [--validate]

Examples:
  scripts/update-plannotator.sh latest
  scripts/update-plannotator.sh 0.19.0
  scripts/update-plannotator.sh v0.19.0 --validate

Updates:
  pkgs/plannotator/default.nix
  modules/home-manager/agents/opencode.nix
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

for command in curl jq nix perl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/plannotator/default.nix"
opencode_file="$repo_root/modules/home-manager/agents/opencode.nix"

if [[ ! -f "$package_file" || ! -f "$opencode_file" ]]; then
  echo "Run this script from inside the nix-config repository." >&2
  exit 1
fi

if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/backnotprop/plannotator/releases/latest"
else
  version_without_v="${requested_version#v}"
  release_url="https://api.github.com/repos/backnotprop/plannotator/releases/tags/v${version_without_v}"
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

darwin_asset="plannotator-darwin-arm64"
linux_asset="plannotator-linux-x64"
darwin_digest=$(asset_digest "$darwin_asset")
linux_digest=$(asset_digest "$linux_asset")

if [[ -z "$darwin_digest" || -z "$linux_digest" ]]; then
  echo "Release $tag_name is missing one or more required CLI assets." >&2
  echo "Required assets: $darwin_asset, $linux_asset" >&2
  exit 1
fi

darwin_hash=$(digest_to_sri "$darwin_digest")
linux_hash=$(digest_to_sri "$linux_digest")

NEW_VERSION="$new_version" perl -0pi -e 's/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/' "$package_file"
DARWIN_HASH="$darwin_hash" perl -0pi -e 's/(aarch64-darwin = \{\n\s+name = "plannotator-darwin-arm64";\n\s+hash = ")sha256-[^"]+(";)/$1$ENV{DARWIN_HASH}$2/' "$package_file"
LINUX_HASH="$linux_hash" perl -0pi -e 's/(x86_64-linux = \{\n\s+name = "plannotator-linux-x64";\n\s+hash = ")sha256-[^"]+(";)/$1$ENV{LINUX_HASH}$2/' "$package_file"
NEW_VERSION="$new_version" perl -0pi -e 's/\@plannotator\/opencode\@[^\"]+/\@plannotator\/opencode\@$ENV{NEW_VERSION}/g' "$opencode_file"

echo "Updated plannotator: $old_version -> $new_version"
echo "Updated files:"
echo "  $package_file"
echo "  $opencode_file"
echo "Hashes:"
echo "  $darwin_asset: $darwin_hash"
echo "  $linux_asset: $linux_hash"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
