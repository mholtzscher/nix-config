#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ${0##*/} <revision|latest> [--validate]" >&2
  exit 2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

requested_revision="$1"
validate=false
if [[ $# -eq 2 ]]; then
  [[ "$2" == "--validate" ]] || usage
  validate=true
fi

for command in awk curl jq nix nix-prefetch-url perl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo="plannotator/herdr-annotate"
repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/herdr-annotate/default.nix"
revision="$requested_revision"
[[ "$revision" == "latest" ]] && revision="main"

commit_json=$(curl --fail --silent --show-error --location \
  "https://api.github.com/repos/$repo/commits/$revision")
new_rev=$(jq -r '.sha // empty' <<<"$commit_json")
if [[ -z "$new_rev" ]]; then
  echo "Could not resolve revision: $requested_revision" >&2
  exit 1
fi

package_json=$(curl --fail --silent --show-error --location \
  "https://raw.githubusercontent.com/$repo/$new_rev/package.json")
new_version=$(jq -r '.version // empty' <<<"$package_json")
if [[ -z "$new_version" ]]; then
  echo "Could not determine package version at revision: $new_rev" >&2
  exit 1
fi

tui_version=$(curl --fail --silent --show-error --location \
  "https://raw.githubusercontent.com/$repo/$new_rev/plannotator-tui.version" | tr -d '[:space:]')
if [[ -z "$tui_version" ]]; then
  echo "Could not determine plannotator-tui version at revision: $new_rev" >&2
  exit 1
fi

tui_checksums=$(curl --fail --silent --show-error --location \
  "https://github.com/plannotator/plannotator-tui/releases/download/v$tui_version/SHA256SUMS")
tui_systems=(aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux)
tui_targets=(aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu)
tui_hashes=()
for target in "${tui_targets[@]}"; do
  hex_hash=$(awk -v asset="plannotator-tui-$target" '$2 == asset { print $1 }' <<<"$tui_checksums")
  if [[ -z "$hex_hash" ]]; then
    echo "Could not find checksum for plannotator-tui-$target" >&2
    exit 1
  fi
  tui_hashes+=("$(nix hash convert --hash-algo sha256 --to sri "$hex_hash")")
done

archive_url="https://github.com/$repo/archive/$new_rev.tar.gz"
echo "-> Fetching source archive for ${new_rev:0:12}..."
unpacked_hash=$(nix-prefetch-url --unpack "$archive_url" 2>/dev/null)
sri_hash=$(nix hash convert --hash-algo sha256 --to sri "sha256:$unpacked_hash" 2>/dev/null)

old_version=$(perl -ne 'print "$1\n" and exit if /version = "([^"]+)";/' "$package_file")
old_rev=$(perl -ne 'print "$1\n" and exit if /rev = "([^"]+)";/' "$package_file")
old_tui_version=$(perl -ne 'print "$1\n" and exit if /plannotatorTuiVersion = "([^"]+)";/' "$package_file")

NEW_VERSION="$new_version" NEW_REV="$new_rev" SRI_HASH="$sri_hash" TUI_VERSION="$tui_version" perl -0pi -e '
  s/version = "[^"]+";/version = "$ENV{NEW_VERSION}";/;
  s/rev = "[^"]+";/rev = "$ENV{NEW_REV}";/;
  s/(src = fetchFromGitHub \{.*?hash = ")sha256-[^"]+(";)/$1$ENV{SRI_HASH}$2/s;
  s/plannotatorTuiVersion = "[^"]+";/plannotatorTuiVersion = "$ENV{TUI_VERSION}";/;
' "$package_file"

for i in "${!tui_systems[@]}"; do
  TUI_TARGET="${tui_targets[$i]}" TUI_HASH="${tui_hashes[$i]}" perl -0pi -e '
    s/(target = "\Q$ENV{TUI_TARGET}\E";\s+hash = ")[^"]+(";)/$1$ENV{TUI_HASH}$2/;
  ' "$package_file"
done

if ! grep -Fq "version = \"$new_version\";" "$package_file" ||
  ! grep -Fq "rev = \"$new_rev\";" "$package_file" ||
  ! grep -Fq "hash = \"$sri_hash\";" "$package_file" ||
  ! grep -Fq "plannotatorTuiVersion = \"$tui_version\";" "$package_file"; then
  echo "Error: failed to update $package_file" >&2
  exit 1
fi
for i in "${!tui_systems[@]}"; do
  if ! grep -Fq "hash = \"${tui_hashes[$i]}\";" "$package_file"; then
    echo "Error: failed to update plannotator-tui hash for ${tui_systems[$i]}" >&2
    exit 1
  fi
done

echo "Updated herdr-annotate: $old_version (${old_rev:0:12}) -> $new_version (${new_rev:0:12})"
echo "Source hash: $sri_hash"
echo "Updated plannotator-tui: $old_tui_version -> $tui_version"
echo "Updated files:"
echo "  $package_file"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
