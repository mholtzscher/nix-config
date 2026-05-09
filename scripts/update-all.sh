#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/update-all.sh [--validate]

Updates all packages under pkgs/ to their latest GitHub release.

Examples:
  scripts/update-all.sh
  scripts/update-all.sh --validate
USAGE
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

validate=false
if [[ $# -eq 1 ]]; then
  case "$1" in
    --validate) validate=true ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
fi

repo_root=$(git rev-parse --show-toplevel)
errors=0

# Discover all package update scripts (scripts/update-<name>.sh)
# that use the shared update-from-github.sh framework.
# This avoids an explicit registry — just drop a new script in scripts/
# and it'll be picked up.
update_scripts=()
while IFS= read -r -d '' script; do
  update_scripts+=("$script")
done < <(find "$repo_root/scripts" -maxdepth 1 -name 'update-*.sh' ! -name 'update-from-github.sh' ! -name 'update-all.sh' -print0 | sort -z)

if [[ ${#update_scripts[@]} -eq 0 ]]; then
  echo "No package update scripts found." >&2
  exit 1
fi

echo "Updating all packages to latest release..."
echo ""

for script in "${update_scripts[@]}"; do
  pkg_name="$(basename "$script" .sh | sed 's/^update-//')"
  printf "→ %s ... " "$pkg_name"

  if output="$("$script" "latest" 2>&1)"; then
    echo "✓"
    # Show the version change summary line if present
    echo "$output" | grep -E "^Updated " | sed 's/^/  /' || true
  else
    echo "✗"
    echo "$output" | head -5 | sed 's/^/  /'
    errors=$((errors + 1))
  fi
  echo ""
done

if [[ "$errors" -gt 0 ]]; then
  echo "Failed: $errors update(s) failed."
  exit 1
fi

echo "All packages up to date."

if [[ "$validate" == true ]]; then
  echo "→ Running validation..."
  "$repo_root/scripts/agent-validate.sh"
else
  echo "Next: ./scripts/agent-validate.sh"
fi
