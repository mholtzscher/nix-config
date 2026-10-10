#!/usr/bin/env bash
# One-time handoff preparation. Never applies Nix or modifies secret files.
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Usage: bash scripts/prepare-nix-restoration.sh" >&2
  exit 2
fi

mise_bin="${MISE_BIN:-$HOME/.local/bin/mise}"
if [[ ! -x "$mise_bin" ]]; then
  echo "Set MISE_BIN to the native Mise executable before running this script." >&2
  exit 1
fi

umask 077
state="$HOME/.local/state/nix-restoration"
config_dir="$HOME/.config/mise"
names=(config.toml config.personal.toml config.work.toml config.local.toml miserc.toml)
has_config=false
for name in "${names[@]}"; do
  if [[ -e "$config_dir/$name" || -L "$config_dir/$name" ]]; then
    has_config=true
  fi
done
if [[ "$has_config" == false && -f "$state/latest" ]]; then
  echo "Migration configuration already archived; retaining the previous recovery directory."
  exit 0
fi
mkdir -p "$state"
backup="$(mktemp -d "$state/pre-mise-handoff.XXXXXX")"
printf 'Recovery directory: %s\n' "$backup"

# Checkpoint first; stop both migration-owned services before moving config.
"$mise_bin" dot save
"$mise_bin" bootstrap services remove mise-history
"$mise_bin" bootstrap services remove mise-tool-update

mkdir -p "$backup/mise-config"
for name in "${names[@]}"; do
  path="$config_dir/$name"
  if [[ -e "$path" || -L "$path" ]]; then
    mv "$path" "$backup/mise-config/$name"
  fi
done

# Leave source directories, installed tools, history, and the native executable
# in place. The current shell may still need them until Nix has been applied.
printf '%s\n' "$backup" > "$state/latest"
echo "Mise migration configuration archived; automatic services stopped."
echo "Keep this terminal open. Apply the already-built Nix configuration yourself."
