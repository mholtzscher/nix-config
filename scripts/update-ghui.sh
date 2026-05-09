#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="ghui"
GITHUB_REPO="kitlangton/ghui"
ASSET_KEY="name"
URL_SUFFIX=""
PLATFORM_ASSETS=(
  "aarch64-darwin:ghui-darwin-arm64.tar.gz"
  "x86_64-darwin:ghui-darwin-x64.tar.gz"
  "aarch64-linux:ghui-linux-arm64.tar.gz"
  "x86_64-linux:ghui-linux-x64.tar.gz"
)

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/update-from-github.sh"
