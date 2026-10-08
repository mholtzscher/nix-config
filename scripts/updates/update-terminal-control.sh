#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/updates/update-terminal-control.sh <version|latest> [--validate]

Updates pkgs/terminal-control/default.nix and recomputes the npm binary
tarball hashes for all supported platforms. The skill flake input is separate.
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

for command in curl jq nix perl git; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/terminal-control/default.nix"
if [[ ! -f "$package_file" ]]; then
  echo "Could not find package file: $package_file" >&2
  exit 1
fi

if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/anomalyco/terminal-control/releases/latest"
else
  version_without_v="${requested_version#v}"
  if [[ ! "$version_without_v" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
    echo "Invalid version: $requested_version" >&2
    exit 2
  fi
  release_url="https://api.github.com/repos/anomalyco/terminal-control/releases/tags/v${version_without_v}"
fi

release_json=$(curl --fail --silent --show-error --location "$release_url")
tag_name=$(jq -er '.tag_name | select(type == "string" and length > 0)' <<<"$release_json")
new_version="${tag_name#v}"
if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
  echo "Invalid release version: $tag_name" >&2
  exit 1
fi
old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")

platform_targets=(
  "aarch64-darwin:darwin-arm64"
  "x86_64-darwin:darwin-x64"
  "aarch64-linux:linux-arm64-gnu"
  "x86_64-linux:linux-x64-gnu"
)
hash_updates=()
for platform_target in "${platform_targets[@]}"; do
  IFS=: read -r platform target <<<"$platform_target"
  url="https://registry.npmjs.org/@kitlangton/terminal-control-${target}/-/terminal-control-${target}-${new_version}.tgz"
  echo "-> Fetching terminal-control ${new_version} for ${platform}..."
  prefetch_json=$(nix store prefetch-file --json "$url")
  hash=$(jq -er '.hash | select(startswith("sha256-"))' <<<"$prefetch_json")
  hash_updates+=("$platform:$hash")
done

# Fetch every platform before changing the package so missing artifacts fail safely.
NEW_VERSION="$new_version" perl -0pi -e 's/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/' "$package_file"
for hash_update in "${hash_updates[@]}"; do
  IFS=: read -r platform hash <<<"$hash_update"
  PLATFORM="$platform" HASH="$hash" perl -0pi -e '
    s{(hashes\s*=\s*\{.*?\Q$ENV{PLATFORM}\E = ")[^"]*(";)}{$1$ENV{HASH}$2}s
  ' "$package_file"
done

echo "Updated terminal-control: $old_version -> $new_version"
echo "Updated files:"
echo "  $package_file"
if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
