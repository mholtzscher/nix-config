#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="herdr-focus-or-tab"
GITHUB_REPO="mholtzscher/herdr-focus-or-tab"

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/updates/common-source.sh"
