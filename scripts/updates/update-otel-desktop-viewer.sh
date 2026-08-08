#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="otel-desktop-viewer"
GITHUB_REPO="CtrlSpice/otel-desktop-viewer"
ASSET_KEY="name"
URL_SUFFIX=""
PLATFORM_ASSETS=(
  "aarch64-darwin:otel-desktop-viewer_darwin_arm64.tar.gz"
  "x86_64-darwin:otel-desktop-viewer_darwin_amd64.tar.gz"
  "aarch64-linux:otel-desktop-viewer_linux_arm64.tar.gz"
  "x86_64-linux:otel-desktop-viewer_linux_amd64.tar.gz"
)

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/updates/common.sh"
