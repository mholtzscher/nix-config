#!/usr/bin/env bash
# Hand off only Iosevka and JetBrains Mono Nerd Fonts. Never applies Nix.
set -euo pipefail

if [[ $(uname -s) != Darwin ]]; then
  echo "Run this on a Mac after applying the staged Nix font removal." >&2
  exit 1
fi
for command in brew mise ditto; do
  command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
cd "$HOME"
config_dir="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
caskroom="$(brew --prefix)/Caskroom"
fonts_dir="$HOME/Library/Fonts"
casks=(font-iosevka-nerd-font font-jetbrains-mono-nerd-font)

is_brew_owned() {
  [[ -e "$caskroom/$1/.metadata" || -L "$caskroom/$1/.metadata" ]]
}
is_mise_owned() {
  local receipt
  for receipt in "$caskroom/$1"/*/.mise-cask.toml; do
    [[ ! -f "$receipt" ]] || return 0
  done
  return 1
}
for cask in "${casks[@]}"; do
  if ! grep -Eq "^[[:space:]]*\"brew-cask:$cask\"[[:space:]]*=" "$config_dir/config.toml"; then
    echo "Missing Mise declaration for $cask. Sync the workstation config first." >&2
    exit 1
  fi
  if is_brew_owned "$cask" && is_mise_owned "$cask"; then
    echo "$cask has both Homebrew metadata and a Mise receipt. Stop and investigate." >&2
    exit 1
  fi
done
mise bootstrap packages status

shopt -s nullglob
fonts=(
  "$fonts_dir"/Iosevka*NerdFont*.ttf
  "$fonts_dir"/Iosevka*NerdFont*.otf
  "$fonts_dir"/JetBrainsMono*NerdFont*.ttf
  "$fonts_dir"/JetBrainsMono*NerdFont*.otf
)
# Do not unregister a Homebrew font family without a usable backup source.
for cask in "${casks[@]}"; do
  if is_brew_owned "$cask"; then
    prefix=Iosevka
    [[ $cask != font-jetbrains-mono-nerd-font ]] || prefix=JetBrainsMono
    found=false
    for font in "${fonts[@]-}"; do
      if [[ ${font##*/} == "$prefix"* && -f "$font" ]]; then
        found=true
      fi
    done
    if ! $found; then
      echo "$cask is Homebrew-owned but its user fonts are missing. Nothing removed." >&2
      exit 1
    fi
  fi
done

echo "Only the two Nerd Font families will be migrated. Other fonts and settings are untouched."
read -r -p "Back up the fonts and transfer ownership to Mise? [y/N] " answer
[[ $answer == y || $answer == Y ]] || exit 0
umask 077
backup=$(mktemp -d "$HOME/mise-fonts-backup.XXXXXX")
printf 'Font recovery directory: %s\n' "$backup"
for font in "${fonts[@]-}"; do
  [[ -n "$font" ]] || continue
  # A broken symlink is not a recoverable font; stop before any uninstall.
  test -f "$font"
  ditto "$font" "$backup/${font##*/}"
  test -f "$backup/${font##*/}"
done

on_exit() {
  local status=$?
  local font
  trap - EXIT
  if [[ $status -ne 0 ]]; then
    mkdir -p "$fonts_dir"
    for font in "$backup"/*; do
      if [[ ! -e "$fonts_dir/${font##*/}" && ! -L "$fonts_dir/${font##*/}" ]]; then
        ditto "$font" "$fonts_dir/${font##*/}" || echo "Could not restore $font" >&2
      fi
    done
    echo "Handoff stopped; missing original fonts were restored. Keep the backup." >&2
  fi
  printf 'Original font files retained at: %s\n' "$backup"
  exit "$status"
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cask in "${casks[@]}"; do
  if is_brew_owned "$cask"; then
    brew uninstall --cask "$cask"
  fi
done
# Old fonts stay in the recovery directory; restoring them before install can
# prevent adoption when the current Nerd Fonts release has different contents.
mise bootstrap packages apply brew-cask:font-iosevka-nerd-font brew-cask:font-jetbrains-mono-nerd-font
for cask in "${casks[@]}"; do
  if is_brew_owned "$cask" || ! is_mise_owned "$cask"; then
    echo "$cask ownership is not confirmed. Keep the backup and investigate." >&2
    exit 1
  fi
  echo "$cask: Mise-owned"
done
echo "Check both font families in Font Book, then restart terminals/editors to refresh their fonts."
