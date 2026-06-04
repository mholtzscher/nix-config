#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/update-glimpseui.sh <version|latest> [--validate]

Updates pkgs/glimpseui/default.nix to a Glimpse GitHub release tag and refreshes
its fetchFromGitHub source hash.

Examples:
  scripts/update-glimpseui.sh latest
  scripts/update-glimpseui.sh 0.8.1 --validate
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
    *) usage >&2; exit 2 ;;
  esac
fi

for command in curl jq nix perl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/glimpseui/default.nix"

if [[ ! -f "$package_file" ]]; then
  echo "Could not find package file: $package_file" >&2
  echo "Run this script from inside the nix-config repository." >&2
  exit 1
fi

if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/HazAT/glimpse/releases/latest"
else
  version_without_v="${requested_version#v}"
  release_url="https://api.github.com/repos/HazAT/glimpse/releases/tags/v${version_without_v}"
fi

release_json=$(curl --fail --silent --show-error --location "$release_url")
tag_name=$(jq -r '.tag_name // empty' <<<"$release_json")

if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
  echo "Could not determine release tag from $release_url" >&2
  exit 1
fi

new_version="${tag_name#v}"
old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")

prefetch_json=$(nix flake prefetch "github:HazAT/glimpse/${tag_name}" --json)
new_hash=$(jq -r '.hash // empty' <<<"$prefetch_json")

if [[ -z "$new_hash" || "$new_hash" == "null" ]]; then
  echo "Could not determine source hash for $tag_name" >&2
  exit 1
fi

NEW_VERSION="$new_version" NEW_HASH="$new_hash" perl -0pi -e '
  s/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/;
  s/(repo = "glimpse";\n\s+rev = "v\$\{version\}";\n\s+hash = ")sha256-[^"]+";/$1$ENV{NEW_HASH}";/;
' "$package_file"

echo "Updated glimpseui: $old_version -> $new_version"
echo "Updated files:"
echo "  $package_file"
echo "Source hash: $new_hash"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
