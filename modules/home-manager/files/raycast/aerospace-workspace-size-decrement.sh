#!/usr/bin/env zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Aerospace Workspace Decrement
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📉
# @raycast.argument1 { "type": "text", "placeholder": "Decrement amount (default: 5)", "optional": true }

# Documentation:
# @raycast.description Decrement Aerospace workspace size by percentage (default 5%)
# @raycast.author mholtzscher
# @raycast.authorURL https://raycast.com/mholtzscher

# Use -5 as default (decrement) if no argument provided
AMOUNT="${1:--5}"

nu -c "source '~/Library/Application Support/nushell/config.nu'; aerospace_workspace_adjust $AMOUNT"
