#!/usr/bin/env bash
# Script to capture monitor EDID when working properly
# Run this BEFORE switching to another KVM input

EDID_DIR="$HOME/.config/hypr/edid"
mkdir -p "$EDID_DIR"

echo "Capturing EDID data for DP-1..."

# Find the EDID file in sysfs
for edid_file in /sys/class/drm/card*/card*-DP-*/edid; do
    if [ -f "$edid_file" ]; then
        connector=$(echo "$edid_file" | grep -oP 'card\d+-DP-\d+')
        echo "Found: $connector"
        
        # Copy the EDID
        cp "$edid_file" "$EDID_DIR/dp1.bin"
        
        # Decode it to see what we got
        if command -v edid-decode >/dev/null 2>&1; then
            echo ""
            echo "=== EDID Info ==="
            edid-decode "$EDID_DIR/dp1.bin" | grep -E "(Monitor name|Detailed mode|DTD)"
        fi
        
        echo ""
        echo "EDID saved to: $EDID_DIR/dp1.bin"
        echo "You can now use this as an override if KVM doesn't pass EDID properly"
        break
    fi
done
