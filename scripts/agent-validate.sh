#!/usr/bin/env bash
set -euo pipefail

# Validate the current platform's Nix configuration using nh.
# Auto-detects OS, picks the appropriate host, and runs the correct nh build command.

HOST=""
USER="${USER:-$(whoami)}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: agent-validate.sh [OPTIONS] [HOST]

Auto-detect the current platform, select the matching host configuration,
and run the appropriate `nh` build command for validation.

Options:
  -h, --help       Show this help
  --host HOST      Override auto-detected host
  --user USER      Override user for home-manager builds (default: current user)

Examples:
  ./scripts/agent-validate.sh              # Auto-detect everything
  ./scripts/agent-validate.sh nixos-desktop  # Validate specific host
  ./scripts/agent-validate.sh --host wanda # Validate Ubuntu host
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --host) HOST="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *) HOST="$1"; shift ;;
  esac
done

cd "$REPO_ROOT"

OS="$(uname -s)"
PLATFORM=""
HOSTS_DIR=""
BUILD_CMD=""

if [[ "$OS" == "Darwin" ]]; then
  PLATFORM="darwin"
  HOSTS_DIR="hosts/darwin"
  BUILD_CMD="darwin"
elif [[ "$OS" == "Linux" ]]; then
  if [[ -f /etc/NIXOS ]]; then
    PLATFORM="nixos"
    HOSTS_DIR="hosts/nixos"
    BUILD_CMD="os"
  else
    PLATFORM="ubuntu"
    HOSTS_DIR="hosts/ubuntu"
    BUILD_CMD="home"
  fi
else
  echo "Unsupported OS: $OS" >&2
  exit 1
fi

# Determine host
if [[ -z "$HOST" ]]; then
  HOSTS=("$HOSTS_DIR"/*/)
  HOSTS=("${HOSTS[@]%/}")
  HOSTS=("${HOSTS[@]##*/}")

  if [[ ${#HOSTS[@]} -eq 0 ]]; then
    echo "No hosts found in $HOSTS_DIR" >&2
    exit 1
  elif [[ ${#HOSTS[@]} -eq 1 ]]; then
    HOST="${HOSTS[0]}"
    echo "Found single host: $HOST"
  else
    # Try to match current hostname
    CURRENT_HOSTNAME="$(hostname)"
    for h in "${HOSTS[@]}"; do
      if [[ "$h" == "$CURRENT_HOSTNAME" ]]; then
        HOST="$h"
        echo "Matched hostname: $HOST"
        break
      fi
    done

    if [[ -z "$HOST" ]]; then
      echo "Multiple hosts available in $HOSTS_DIR: ${HOSTS[*]}" >&2
      echo "Please specify one: ./scripts/agent-validate.sh <host>" >&2
      exit 1
    fi
  fi
fi

# Validate host exists
if [[ ! -d "$HOSTS_DIR/$HOST" ]]; then
  echo "Host '$HOST' not found in $HOSTS_DIR" >&2
  echo "Available hosts: $(ls "$HOSTS_DIR")" >&2
  exit 1
fi

# Run build
if [[ "$BUILD_CMD" == "home" ]]; then
  INSTALLABLE=".#${USER}@${HOST}"
  echo "→ nh home build $INSTALLABLE"
  nh home build "$INSTALLABLE"
else
  INSTALLABLE=".#${HOST}"
  echo "→ nh $BUILD_CMD build $INSTALLABLE"
  nh "$BUILD_CMD" build "$INSTALLABLE"
fi

echo ""
echo "Build successful. To apply, run:"
if [[ "$BUILD_CMD" == "home" ]]; then
  echo "  nh home switch $INSTALLABLE"
else
  echo "  nh $BUILD_CMD switch $INSTALLABLE"
fi
