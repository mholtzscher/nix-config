#!/usr/bin/env bash
# Personal-Mac handoff only. Never applies Nix or deletes app settings.
set -euo pipefail

if [[ $(uname -s) != Darwin ]]; then
  echo "Run this on the personal Mac after applying the staged Nix changes." >&2
  exit 1
fi
for command in brew mise ditto; do
  command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
cd "$HOME"
config_dir="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
caskroom="$(brew --prefix)/Caskroom"
casks=(bruno discord)
apps=(Bruno Discord)

for cask in "${casks[@]}"; do
  if ! grep -Eq "^[[:space:]]*\"brew-cask:$cask\"[[:space:]]*=" "$config_dir/config.personal.toml"; then
    echo "Missing personal-profile Mise declaration for $cask. Sync the workstation config first." >&2
    exit 1
  fi
done
mise -E personal bootstrap packages status

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

# Avoid ambiguous ownership or a missing recovery source before any uninstall.
for i in "${!casks[@]}"; do
  cask="${casks[$i]}"
  if is_brew_owned "$cask"; then
    if is_mise_owned "$cask"; then
      echo "$cask has both Homebrew metadata and a Mise receipt. Stop and investigate." >&2
      exit 1
    fi
    if [[ ! -d "/Applications/${apps[$i]}.app/Contents" ]]; then
      echo "$cask is Homebrew-owned but its /Applications bundle is missing. Nothing removed." >&2
      exit 1
    fi
  fi
done

echo "Quit Bruno and Discord before continuing."
read -r -p "Back up their bundles and transfer ownership to Mise? [y/N] " answer
[[ $answer == y || $answer == Y ]] || exit 0

umask 077
backup=$(mktemp -d "$HOME/mise-bruno-discord-backup.XXXXXX")
printf 'Recovery directory: %s\n' "$backup"
for app in "${apps[@]}"; do
  if [[ -d "/Applications/$app.app/Contents" ]]; then
    ditto "/Applications/$app.app" "$backup/$app.app"
    test -d "$backup/$app.app/Contents"
  fi
done

restore_apps() {
  local app
  local failed=0
  for app in "${apps[@]}"; do
    if [[ -d "$backup/$app.app/Contents" && ! -e "/Applications/$app.app" && ! -L "/Applications/$app.app" ]]; then
      ditto "$backup/$app.app" "/Applications/$app.app" || failed=1
    fi
  done
  return "$failed"
}
on_exit() {
  local status=$?
  trap - EXIT
  if ! restore_apps; then
    echo "Some bundles could not be restored. Recover them from $backup." >&2
    status=1
  fi
  printf 'App backups retained at: %s\n' "$backup"
  [[ $status == 0 ]] || echo "Handoff stopped. Do not force past an adoption error." >&2
  exit "$status"
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cask in "${casks[@]}"; do
  if is_brew_owned "$cask"; then
    brew uninstall --cask "$cask"
    restore_apps
  fi
done
mise -E personal bootstrap packages apply brew-cask:bruno brew-cask:discord
for cask in "${casks[@]}"; do
  if is_brew_owned "$cask" || ! is_mise_owned "$cask"; then
    echo "$cask ownership is not confirmed. Keep the backup and investigate." >&2
    exit 1
  fi
  echo "$cask: Mise-owned"
done
echo "Launch Bruno and Discord to check their existing settings and data."
