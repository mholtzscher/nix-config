#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="herdr-navigator"
GITHUB_REPO="thanhdat77/herdr-navigator"

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/updates/common-source.sh"
