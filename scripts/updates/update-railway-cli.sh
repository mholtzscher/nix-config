#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/updates/update-railway-cli.sh <version|latest> [--validate]

Updates pkgs/railway-cli/default.nix with the given version tag and recomputes
the source hashes for all supported platforms.
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
package_file="$repo_root/pkgs/railway-cli/default.nix"

if [[ ! -f "$package_file" ]]; then
  echo "Could not find package file: $package_file" >&2
  echo "Run this script from inside the nix-config repository." >&2
  exit 1
fi

# Fetch release info from GitHub
if [[ "$requested_version" == "latest" ]]; then
  release_url="https://api.github.com/repos/railwayapp/cli/releases/latest"
else
  version_without_v="${requested_version#v}"
  release_url="https://api.github.com/repos/railwayapp/cli/releases/tags/v${version_without_v}"
fi

release_json=$(curl --fail --silent --show-error --location "$release_url")
tag_name=$(jq -r '.tag_name // empty' <<<"$release_json")

if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
  echo "Could not determine release tag from $release_url" >&2
  exit 1
fi

new_version="${tag_name#v}"
old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")

# Rust target triples for each Nix platform
declare -A RUST_TARGETS
RUST_TARGETS=(
  ["aarch64-darwin"]="aarch64-apple-darwin"
  ["x86_64-darwin"]="x86_64-apple-darwin"
  ["aarch64-linux"]="aarch64-unknown-linux-musl"
  ["x86_64-linux"]="x86_64-unknown-linux-musl"
)

echo "-> Fetching hashes for railway v${new_version}..."

declare -A NEW_HASHES
errors=0

for platform in "${!RUST_TARGETS[@]}"; do
  rust_target="${RUST_TARGETS[$platform]}"
  tarball="railway-v${new_version}-${rust_target}.tar.gz"
  url="https://github.com/railwayapp/cli/releases/download/v${new_version}/${tarball}"

  printf "  %-18s %s ... " "$platform" "$tarball"

  # Use API digest if available, otherwise prefetch
  digest=$(jq -r --arg name "$tarball" '.assets[] | select(.name == $name) | .digest // empty' <<<"$release_json")

  if [[ -n "$digest" ]]; then
    # Convert hex digest to SRI format
    hex="${digest#sha256:}"
    hash=$(nix hash convert --hash-algo sha256 --to sri "$hex" 2>/dev/null)
    echo "✓ (API digest)"
  else
    # Fall back to nix-prefetch-url
    raw_hash=$(nix-prefetch-url "$url" 2>/dev/null)
    hash=$(nix hash convert --hash-algo sha256 --to sri "sha256:${raw_hash}" 2>/dev/null)
    echo "✓ (prefetched)"
  fi

  if [[ -z "$hash" ]]; then
    echo "  Error: could not compute hash for ${platform}" >&2
    errors=$((errors + 1))
    continue
  fi

  NEW_HASHES[$platform]="$hash"
done

if [[ "$errors" -gt 0 ]]; then
  echo "Failed: $errors platform(s) could not be updated." >&2
  exit 1
fi

# Update version in package file
NEW_VERSION="$new_version" perl -0pi -e 's/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/' "$package_file"

# Update hashes in package file
for platform in "${!NEW_HASHES[@]}"; do
  hash="${NEW_HASHES[$platform]}"
  PLATFORM="$platform" HASH="$hash" perl -0pi -e '
    s{(hashes\s*=\s*\{.*?\Q$ENV{PLATFORM}\E = ")[^"]*(";)}{$1$ENV{HASH}$2}s
  ' "$package_file"
done

echo ""
echo "Updated railway-cli: $old_version -> $new_version"
echo "Updated files:"
echo "  $package_file"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
