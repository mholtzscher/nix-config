#!/usr/bin/env bash
# Transfer only the configured work-Mac GUI casks to Mise. Never applies Nix.
set -euo pipefail

dry_run=false
force_handy=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --force-handy) force_handy=true ;;
    --help|-h)
      echo "Usage: bash scripts/migrate-work-mac-gui.sh [--dry-run] [--force-handy]"
      echo "Quit the affected apps and apply the staged Nix changes first."
      echo "--force-handy repairs the stale Homebrew Handy record seen on the personal Mac."
      exit 0
      ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

if [[ $(uname -s) != Darwin ]]; then
  echo "This script is for the work Mac only." >&2
  exit 1
fi
for command in brew mise ditto; do
  command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done

# Use the global workstation config, not a project's Mise overrides.
cd "$HOME"
config_dir="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
casks=(arc cleanshot deskpad google-chrome raycast slack handy jetbrains-toolbox)
apps=("Arc" "CleanShot X" "DeskPad" "Google Chrome" "Raycast" "Slack" "Handy" "JetBrains Toolbox")

# Do not drop Homebrew ownership unless the replacement declarations are available.
for cask in "${casks[@]}"; do
  config="$config_dir/config.toml"
  [[ $cask != jetbrains-toolbox ]] || config="$config_dir/config.work.toml"
  if ! grep -Eq "^[[:space:]]*\"brew-cask:$cask\"[[:space:]]*=" "$config"; then
    echo "Missing Mise declaration for $cask in $config. Sync the workstation config first." >&2
    exit 1
  fi
done
mise -E work bootstrap packages status
installed=$(brew list --cask)

is_brew_owned() {
  grep -Fxq -- "$1" <<< "$installed"
}

# A listed cask with a missing bundle needs investigation before uninstalling it.
for i in "${!casks[@]}"; do
  if is_brew_owned "${casks[$i]}" && [[ ! -d "/Applications/${apps[$i]}.app/Contents" ]]; then
    echo "${casks[$i]} is Homebrew-listed but its /Applications bundle is missing. Nothing removed." >&2
    exit 1
  fi
done

echo "Scope: ${casks[*]} (work profile only). No app data or unrelated casks will be removed."
if $dry_run; then
  for cask in "${casks[@]}"; do
    if is_brew_owned "$cask"; then
      echo "Would back up, unregister from Homebrew, restore, and adopt: $cask"
    fi
  done
  mise -E work bootstrap packages apply --manager brew-cask --dry-run
  exit 0
fi

umask 077
backup=$(mktemp -d "$HOME/mise-work-gui-backup.XXXXXX")
printf 'Recovery directory (keep until verified): %s\n' "$backup"

# Finish every backup before the first uninstall. Never copy user settings or credentials.
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
      echo "Restoring $app.app"
      ditto "$backup/$app.app" "/Applications/$app.app" || failed=1
    fi
  done
  return "$failed"
}

on_exit() {
  local status=$?
  trap - EXIT
  if ! restore_apps; then
    echo "Some bundles could not be restored. Recover them from $backup; do not delete it." >&2
    status=1
  fi
  printf 'App backups retained at: %s\n' "$backup"
  if [[ $status -ne 0 ]]; then
    echo "Handoff stopped. Bundles were restored where missing; settings were not deleted." >&2
  fi
  exit "$status"
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cask in "${casks[@]}"; do
  if is_brew_owned "$cask"; then
    if [[ $cask == handy ]] && $force_handy; then
      brew uninstall --cask --force handy
    elif ! brew uninstall --cask "$cask"; then
      if [[ $cask == handy ]]; then
        echo "If this is the stale Handy record, rerun with --force-handy after checking the error." >&2
      fi
      exit 1
    fi
    restore_apps
  fi
done

mise -E work bootstrap packages apply --manager brew-cask
echo "Checking remaining Homebrew casks:"
remaining=$(brew list --cask)
for cask in "${casks[@]}"; do
  if grep -Fxq -- "$cask" <<< "$remaining"; then
    echo "$cask still appears in Homebrew; ownership transfer needs investigation." >&2
    exit 1
  fi
done
mise -E work bootstrap packages status
echo "Handoff finished. Launch the apps to verify them; re-enable Raycast launch-at-login if needed."
