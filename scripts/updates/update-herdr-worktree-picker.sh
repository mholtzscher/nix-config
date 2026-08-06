#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="herdr-worktree-picker"
GITHUB_REPO="mholtzscher/herdr-worktree-picker"

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/updates/common-source.sh"
