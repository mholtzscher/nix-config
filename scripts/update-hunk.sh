#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="hunk"
GITHUB_REPO="modem-dev/hunk"
ASSET_KEY="assetName"
URL_SUFFIX=".tar.gz"
PLATFORM_ASSETS=(
  "aarch64-darwin:hunkdiff-darwin-arm64"
  "x86_64-darwin:hunkdiff-darwin-x64"
  "aarch64-linux:hunkdiff-linux-arm64"
  "x86_64-linux:hunkdiff-linux-x64"
)

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/update-from-github.sh"
