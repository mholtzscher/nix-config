#!/usr/bin/env bash
# Wrapper script for codesnap that copies output to clipboard
# Reads code from stdin, generates snapshot, copies to clipboard

codesnap --from-code \
  --file-path "${1:-code.txt}" \
  --has-breadcrumbs true \
  --code-font-family 'Iosevka Nerd Font Mono' \
  --watermark '' \
  --output /tmp/codesnap.png 2>/dev/null || exit 1

# Copy to clipboard based on platform
if [[ "$OSTYPE" == "darwin"* ]]; then
  osascript -e 'set the clipboard to (read (POSIX file "/tmp/codesnap.png") as «class PNGf»)'
else
  nohup wl-copy --type image/png < /tmp/codesnap.png >/dev/null 2>&1 &
fi
