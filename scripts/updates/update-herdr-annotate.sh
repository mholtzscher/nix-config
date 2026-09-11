#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/updates/update-herdr-annotate.sh <revision|latest> [--validate]

Updates pkgs/herdr-annotate/default.nix. <revision> is a commit of
plannotator/herdr-annotate (or "latest" for its default branch).

Upstream ships no build step for this plugin: Herdr runs scripts/fetch-*.sh, which download a
prebuilt binary per platform. The derivation therefore pins one source revision plus three
independent versions, all read out of the pinned source tree:

  herdr-plugin.toml        version                  -> package version
  herdr-annotate.version   native runtime           -> release rust-lite-v<version>
  plannotator-tui.version  document review binary   -> release v<version>

Both binaries are release assets for four platforms; their SHA256SUMS files are the source of
truth for the hashes. The rest of the plugin root (manifest, scripts, skills) comes from the
source archive.
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

requested_revision="$1"
validate=false
if [[ $# -eq 2 ]]; then
  [[ "$2" == "--validate" ]] || {
    usage >&2
    exit 2
  }
  validate=true
fi

for command in awk curl jq nix nix-prefetch-url perl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

repo="plannotator/herdr-annotate"
tui_repo="plannotator/plannotator-tui"
repo_root=$(git rev-parse --show-toplevel)
package_file="$repo_root/pkgs/herdr-annotate/default.nix"

# Always name the URL that failed: a moved upstream file used to surface as a bare
# "curl: (22) ... 404" with no hint about which pin went stale.
fetch() {
  local url="$1" body
  if ! body=$(curl --fail --silent --show-error --location "$url"); then
    echo "Error: could not fetch $url" >&2
    exit 1
  fi
  printf '%s' "$body"
}

revision="$requested_revision"
[[ "$revision" == "latest" ]] && revision="main"

new_rev=$(fetch "https://api.github.com/repos/$repo/commits/$revision" | jq -r '.sha // empty')
if [[ -z "$new_rev" ]]; then
  echo "Could not resolve revision: $requested_revision" >&2
  exit 1
fi

raw="https://raw.githubusercontent.com/$repo/$new_rev"

manifest=$(fetch "$raw/herdr-plugin.toml")
# TOML, so no trailing semicolon on the line; the same pattern in common.sh targets Nix files.
new_version=$(perl -ne 'if (/^version = "([^"]+)"/) { print "$1\n"; exit }' <<<"$manifest")
if [[ -z "$new_version" ]]; then
  echo "Could not read the plugin version from herdr-plugin.toml at $new_rev" >&2
  exit 1
fi

# A manifest that no longer runs ./bin/herdr-annotate.exe means upstream reshuffled the plugin
# again (for example back to a source build), and this package needs revisiting.
if ! grep -Fq './bin/herdr-annotate.exe' <<<"$manifest"; then
  echo "Error: herdr-plugin.toml at $new_rev no longer runs ./bin/herdr-annotate.exe;" >&2
  echo "the layout in pkgs/herdr-annotate/default.nix needs to be revisited." >&2
  exit 1
fi

runtime_version=$(tr -d '[:space:]' <<<"$(fetch "$raw/herdr-annotate.version")")
if [[ -z "$runtime_version" ]]; then
  echo "Could not determine the native runtime version from $raw/herdr-annotate.version" >&2
  exit 1
fi

tui_version=$(tr -d '[:space:]' <<<"$(fetch "$raw/plannotator-tui.version")")
if [[ -z "$tui_version" ]]; then
  echo "Could not determine the plannotator-tui version from $raw/plannotator-tui.version" >&2
  exit 1
fi

platforms=(aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux)
targets=(aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu)

# Release asset hashes for one repo, in `platforms` order.
collect_hashes() {
  local release_base="$1" asset_prefix="$2"
  local sums asset hex

  echo "-> Reading SHA256SUMS from $release_base..." >&2
  sums=$(fetch "$release_base/SHA256SUMS")

  for target in "${targets[@]}"; do
    asset="$asset_prefix-$target"
    hex=$(awk -v asset="$asset" '$2 == asset { print $1 }' <<<"$sums")
    if [[ -z "$hex" ]]; then
      echo "Could not find $asset in $release_base/SHA256SUMS" >&2
      exit 1
    fi
    nix hash convert --hash-algo sha256 --to sri "$hex"
  done
}

# Assigning through a command substitution (rather than a process substitution) keeps a failed
# fetch fatal under `set -e`.
runtime_hash_lines=$(collect_hashes \
  "https://github.com/$repo/releases/download/rust-lite-v$runtime_version" "herdr-annotate")
mapfile -t runtime_hashes <<<"$runtime_hash_lines"
tui_hash_lines=$(collect_hashes \
  "https://github.com/$tui_repo/releases/download/v$tui_version" "plannotator-tui")
mapfile -t tui_hashes <<<"$tui_hash_lines"

echo "-> Fetching source archive for ${new_rev:0:12}..."
unpacked_hash=$(nix-prefetch-url --unpack "https://github.com/$repo/archive/$new_rev.tar.gz" 2>/dev/null)
sri_hash=$(nix hash convert --hash-algo sha256 --to sri "sha256:$unpacked_hash" 2>/dev/null)
if [[ -z "$sri_hash" ]]; then
  echo "Could not compute the source hash for $new_rev" >&2
  exit 1
fi

# Edits land in a scratch copy and only replace the package file once every pin has been written
# and verified, so a renamed field upstream cannot leave a half-updated derivation behind.
work_file=$(mktemp)
trap 'rm -f "$work_file"' EXIT
cp "$package_file" "$work_file"

old_version=$(perl -ne 'if (/^  version = "([^"]+)";/) { print "$1\n"; exit }' "$package_file")
old_rev=$(perl -ne 'if (/rev = "([^"]+)";/) { print "$1\n"; exit }' "$package_file")
old_runtime_version=$(perl -ne 'if (/runtimeVersion = "([^"]+)";/) { print "$1\n"; exit }' "$package_file")
old_tui_version=$(perl -ne 'if (/plannotatorTuiVersion = "([^"]+)";/) { print "$1\n"; exit }' "$package_file")

NEW_VERSION="$new_version" NEW_REV="$new_rev" SRC_HASH="$sri_hash" \
  RUNTIME_VERSION="$runtime_version" TUI_VERSION="$tui_version" perl -0pi -e '
    s/^  version = "[^"]+";/  version = "$ENV{NEW_VERSION}";/m;
    s/^    rev = "[^"]+";/    rev = "$ENV{NEW_REV}";/m;
    s/(src = fetchFromGitHub \{.*?hash = ")sha256-[^"]+(";)/$1$ENV{SRC_HASH}$2/s;
    s/^  runtimeVersion = "[^"]+";/  runtimeVersion = "$ENV{RUNTIME_VERSION}";/m;
    s/^  plannotatorTuiVersion = "[^"]+";/  plannotatorTuiVersion = "$ENV{TUI_VERSION}";/m;
  ' "$work_file"

for i in "${!platforms[@]}"; do
  for update in "herdr-annotate:${runtime_hashes[$i]}" "plannotator-tui:${tui_hashes[$i]}"; do
    ASSET="${update%%:*}-${targets[$i]}" HASH="${update#*:}" perl -0pi -e '
      s/(asset = "\Q$ENV{ASSET}\E";\n\s+hash = ")[^"]+(";)/$1$ENV{HASH}$2/;
    ' "$work_file"
  done
done

failure=0
verify_value() { # $1=field name $2=expected value
  grep -Fq "$1 = \"$2\";" "$work_file" || {
    echo "Error: $1 is not $2 in $package_file" >&2
    failure=1
  }
}

verify_value version "$new_version"
verify_value rev "$new_rev"
verify_value runtimeVersion "$runtime_version"
verify_value plannotatorTuiVersion "$tui_version"
grep -Fq "hash = \"$sri_hash\";" "$work_file" || {
  echo "Error: the source hash is not $sri_hash in $package_file" >&2
  failure=1
}

# Asset names are unique across both attrsets, so each hash is checked next to its asset name.
for i in "${!platforms[@]}"; do
  for update in "herdr-annotate:${runtime_hashes[$i]}" "plannotator-tui:${tui_hashes[$i]}"; do
    ASSET="${update%%:*}-${targets[$i]}" HASH="${update#*:}" perl -0ne '
      exit 0 if /asset = "\Q$ENV{ASSET}\E";\n\s+hash = "\Q$ENV{HASH}\E";/;
      print STDERR "Error: $ENV{ASSET} does not have hash $ENV{HASH}\n";
      exit 1;
    ' "$work_file" || failure=1
  done
done

if [[ "$failure" -ne 0 ]]; then
  echo "Error: $package_file is unchanged" >&2
  exit 1
fi

cp "$work_file" "$package_file"

echo "Updated herdr-annotate: $old_version (${old_rev:0:12}) -> $new_version (${new_rev:0:12})"
echo "Source hash: $sri_hash"
echo "Updated native runtime: $old_runtime_version -> $runtime_version"
echo "Updated plannotator-tui: $old_tui_version -> $tui_version"
echo "Updated files:"
echo "  $package_file"

if [[ "$validate" == true ]]; then
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
