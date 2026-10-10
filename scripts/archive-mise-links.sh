#!/usr/bin/env bash
# Archive foreign Mise links only where the built Home Manager owns a path.
# Reads link metadata, not file contents. Never applies Nix.
set -euo pipefail

if [[ $# -ne 1 || ! -d "$1" ]]; then
  echo "Usage: bash scripts/archive-mise-links.sh /path/to/generation/home-files" >&2
  exit 2
fi
gen_files="${1%/}"
case "$gen_files" in
  /*/home-files) ;;
  *) echo "Expected an absolute generation home-files path." >&2; exit 2 ;;
esac

umask 077
state="$HOME/.local/state/nix-restoration"
mkdir -p "$state"
backup="$(mktemp -d "$state/mise-links.XXXXXX")"
printf 'Link recovery directory: %s\n' "$backup"

# Follow only the command-line home-files link, never linked subdirectories.
find -H "$gen_files" -type l -print0 |
  while IFS= read -r -d '' source; do
    relative="${source#"$gen_files/"}"
    case "$relative" in
      ""|/*|..|../*|*/../*|*/..) echo "Invalid generation path." >&2; exit 1 ;;
    esac
    target="$HOME/$relative"
    if [[ -L "$target" ]]; then
      link="$(readlink "$target")"
      case "$link" in
        "$HOME/.config/mise/"*)
          mkdir -p "$backup/$(dirname "$relative")"
          mv "$target" "$backup/$relative"
          printf 'Archived migration link: %s\n' "$target"
          ;;
      esac
    fi
  done

echo "Original link targets and all regular files were left unchanged."
echo "Apply the restored nix-darwin configuration yourself."
