#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "→ Running nixfmt on all *.nix files..."
find . -name '*.nix' -not -path './.direnv/*' -print0 | xargs -0 nixfmt

echo "Format OK."

OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
  echo "→ nh darwin build -q --no-nom"
  nh darwin build -q --no-nom
  echo "Build OK. Apply: nh darwin switch"
  exit 0
fi

if [[ -f /etc/NIXOS ]]; then
  echo "→ nh os build -q --no-nom"
  nh os build -q --no-nom
  echo "Build OK. Apply: nh os switch"
  exit 0
fi

# Home-manager: single host auto-picks, multiple hosts require explicit
HOST="${1:-}"
HOSTS=(hosts/ubuntu/*/)
HOSTS=("${HOSTS[@]%/}")
HOSTS=("${HOSTS[@]##*/}")

if [[ -z "$HOST" ]]; then
  if [[ ${#HOSTS[@]} -eq 1 ]]; then
    HOST="${HOSTS[0]}"
  else
    echo "Hosts: ${HOSTS[*]}" >&2
    echo "Usage: $0 <host>" >&2
    exit 1
  fi
fi

if [[ ! -d "hosts/ubuntu/$HOST" ]]; then
  echo "Unknown host: $HOST" >&2
  exit 1
fi

INSTALLABLE=".#${USER:-$(whoami)}@${HOST}"
echo "→ nh home build -q --no-nom $INSTALLABLE"
nh home build -q --no-nom "$INSTALLABLE"
echo "Build OK. Apply: nh home switch $INSTALLABLE"
