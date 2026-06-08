#!/usr/bin/env bash
set -euo pipefail

PKG_NAME="plannotator"
GITHUB_REPO="backnotprop/plannotator"
ASSET_KEY="name"
URL_SUFFIX=""
PLATFORM_ASSETS=(
  "aarch64-darwin:plannotator-darwin-arm64"
  "x86_64-linux:plannotator-linux-x64"
)

extra_version_updates() {
  local opencode_file="$repo_root/modules/home-manager/agents/opencode.nix"

  NEW_VERSION="$new_version" perl -0pi -e \
    's/\@plannotator\/opencode\@[^\"]+/\@plannotator\/opencode\@$ENV{NEW_VERSION}/g' \
    "$opencode_file"

  echo "  $opencode_file"
}

repo_root=$(git rev-parse --show-toplevel)
source "$repo_root/scripts/updates/common.sh"
