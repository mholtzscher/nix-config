#!/bin/sh
# Install the standalone bootstrap version before removing Nix's Mise package.
set -eu
version=2026.10.8
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    platform=linux-x64-musl
    checksum=043dc6b9077db988269ca2f85059851cb09fc080355350021363e95a5e227f84
    ;;
  Darwin-arm64)
    platform=macos-arm64
    checksum=dd77de9a7574e38d8409fb06fa85e1581415896639d075987791d8c4e5a57b73
    ;;
  *) echo 'Unsupported host platform' >&2; exit 1 ;;
esac
target="$HOME/.local/bin/mise"
if [ -e "$target" ] || [ -L "$target" ]; then
  echo "$target already exists; verify it with mise --version and mise self-update." >&2
  exit 1
fi
mkdir -p "$HOME/.local/bin"
stage=$(mktemp -d "$HOME/.local/bin/.mise-install.XXXXXX")
tmp="$stage/mise"
trap 'rm -f "$tmp"; rmdir "$stage"' EXIT
curl --fail --show-error --silent --location \
  "https://github.com/jdx/mise/releases/download/v$version/mise-v$version-$platform" -o "$tmp"
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$tmp" | cut -d ' ' -f 1)
else
  actual=$(shasum -a 256 "$tmp" | cut -d ' ' -f 1)
fi
[ "$actual" = "$checksum" ] || { echo 'Mise checksum mismatch' >&2; exit 1; }
chmod 755 "$tmp"
"$tmp" --version
mv "$tmp" "$target"
echo "Installed $target. Future updates: $target self-update"
