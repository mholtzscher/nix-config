#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="mermaid-rs-renderer"
GITHUB_REPO="1jehuang/mermaid-rs-renderer"
ASSET_KEY="name"
URL_SUFFIX=""
PLATFORM_ASSETS=(
  "aarch64-darwin:mmdr-aarch64-apple-darwin.tar.gz"
  "x86_64-darwin:mmdr-x86_64-apple-darwin.tar.gz"
  "aarch64-linux:mmdr-aarch64-unknown-linux-gnu.tar.gz"
  "x86_64-linux:mmdr-x86_64-unknown-linux-gnu.tar.gz"
)

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/updates/common.sh"
