#!/usr/bin/env zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Aerospace
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🖥️

# Documentation:
# @raycast.description Toggle Aerospace Enabled
# @raycast.author mholtzscher
# @raycast.authorURL https://raycast.com/mholtzscher

if pgrep -q aerospace; then
  aerospace enable toggle
else
  echo "Aerospace is not running"
fi
