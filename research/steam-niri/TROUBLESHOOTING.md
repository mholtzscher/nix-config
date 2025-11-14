# Steam on Niri: Troubleshooting Guide

## Common Errors and Solutions

### Error 1: "Unable to open a connection to X server"

**Symptoms**:
```
Unable to open a connection to the X server
Error: Cannot open display
```

**Causes** (in order of likelihood):
1. ❌ XWayland not installed
2. ❌ DISPLAY variable not set
3. ❌ XWayland process not running
4. ❌ DBUS not configured

**Diagnostic Steps**:

```bash
# 1. Check if XWayland is installed
which xwayland
# If not found: run `nb` and `nup` to apply configuration

# 2. Check DISPLAY is set
echo $DISPLAY
# If empty or error, try:
export DISPLAY=:0

# 3. Verify XWayland is running in Niri
ps aux | grep -i xwayland
# If not running, start a fresh Niri session

# 4. Test X11 connection
xdpyinfo
# This should output display information without errors

# 5. Check D-Bus
echo $DBUS_SESSION_BUS_ADDRESS
# Should show something like: unix:path=/run/user/1000/bus
```

**Solutions**:

**Solution A**: Install XWayland package
```bash
# Edit hosts/nixos/nixos-desktop.nix
# Add to environment.systemPackages:
xwayland
xorg.xhost
xorg.xdpyinfo

# Then rebuild
nb && nup
```

**Solution B**: Manually set DISPLAY
```bash
export DISPLAY=:0
steam
# or try :1, :2 if :0 doesn't work
```

**Solution C**: Start fresh Niri session
```bash
# Log out completely and log back in
# XWayland should start automatically with Niri
```

---

### Error 2: "SDL_VideoModeOK failed" or "SDL video driver error"

**Symptoms**:
```
SDL_VideoModeOK failed
Could not initialize SDL video mode
SDL: Video mode not available
```

**Causes**:
1. ⚠️ SDL_VIDEODRIVER=wayland conflicts with Steam
2. ❌ Graphics driver issue
3. ❌ XWayland/GPU acceleration not working

**Solutions**:

**Solution A**: Remove SDL_VIDEODRIVER override (recommended)
```bash
# Edit modules/nixos/hosts/nixos-desktop/gaming.nix
# Remove or comment out:
# SDL_VIDEODRIVER = "wayland";

# Then rebuild
nb && nup
```

**Solution B**: Explicitly set to X11
```bash
# Edit modules/nixos/hosts/nixos-desktop/gaming.nix
sessionVariables = {
  SDL_VIDEODRIVER = "x11";  # Use X11
  # ... other variables ...
};

# Then rebuild
nb && nup
```

**Solution C**: Manual override for testing
```bash
export SDL_VIDEODRIVER=x11
steam
```

---

### Error 3: Steam window appears but with black screen

**Symptoms**:
- Steam window opens
- Content area is black or not rendering
- Window manager shows Steam running but frozen

**Causes**:
1. ⚠️ GPU acceleration not enabled
2. ⚠️ NVIDIA driver not properly configured
3. ❌ Missing VA-API libraries

**Solutions**:

**Solution A**: Check NVIDIA configuration
```bash
# Verify nvidia-drm.modeset is enabled in config
cat /proc/cmdline | grep nvidia-drm
# Should show: nvidia-drm.modeset=1

# If not set:
# Edit hosts/nixos/nixos-desktop.nix
boot.kernelParams = [
  "nvidia-drm.modeset=1"  # Must be present
];

# Then rebuild kernel
nb && nup
```

**Solution B**: Enable hardware graphics
```bash
# Verify hardware.graphics is enabled
# Edit hosts/nixos/nixos-desktop.nix
hardware.graphics = {
  enable = true;
  enable32Bit = true;  # Must be true
};

# Then rebuild
nb && nup
```

**Solution C**: Check GPU rendering
```bash
# Test GPU access
glxinfo | grep -i "direct rendering"
# Should say "direct rendering: Yes"

# Test Vulkan
vulkaninfo | grep "GPU" | head -5
# Should show NVIDIA GPU

# If not working, check driver
lspci -k | grep -A 2 VGA
```

**Solution D**: Add VA-API support
```bash
# Edit hosts/nixos/nixos-desktop.nix
hardware.graphics.extraPackages = with pkgs; [
  libva-nvidia-driver
  nvidia-vaapi-driver
];

hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
  libva-nvidia-driver
  nvidia-vaapi-driver
];

# Then rebuild
nb && nup
```

---

### Error 4: Steam freezes or crashes on startup

**Symptoms**:
```
Steam is running
[Frozen process]
Segmentation fault (core dumped)
```

**Causes**:
1. ⚠️ Steam runtime compatibility issue
2. ⚠️ Incompatible Proton version
3. ❌ Corrupted Steam cache

**Solutions**:

**Solution A**: Clear Steam cache
```bash
# Remove Steam runtime cache (preserves games)
rm -rf ~/.cache/steam-overlay
rm -rf ~/.cache/pressure-vessel

# Remove shader cache
rm -rf ~/.cache/shader-cache

# Restart Steam
steam
```

**Solution B**: Reset Steam configuration
```bash
# Backup current config
cp ~/.steam/steam/config/config.vdf ~/.steam/steam/config/config.vdf.backup

# Clear Steam config
rm -rf ~/.steam/steam/config

# Steam will regenerate on next start
steam
```

**Solution C**: Disable Steam Runtime
```bash
# Disable proton runtime (may help with compatibility)
export STEAM_COMPAT_TOOL_PATHS=/var/lib/steam

# Run Steam
steam
```

**Solution D**: Check Steam logs
```bash
# Review Steam startup log
cat ~/.steam/steam/logs/bootstrap.log | tail -50

# Look for specific error messages
grep -i "error\|warning\|failed" ~/.steam/steam/logs/*.log
```

---

### Error 5: Game launches but crashes immediately

**Symptoms**:
```
Starting game...
[Game window appears briefly]
[Game crashes]
Proton log: [Error message]
```

**Causes**:
1. ⚠️ Incompatible Proton version
2. ⚠️ Missing 32-bit libraries
3. ⚠️ Game-specific compatibility issue

**Solutions**:

**Solution A**: Try different Proton version
```bash
# In Steam:
# Game Properties → Compatibility → Proton versions
# Select different version and retry

# Common compatible versions:
# - Proton 9.0 or later (most games)
# - Proton GE (community maintained, often better)
```

**Solution B**: Enable Proton logging
```bash
# Set environment variable for verbose logging
export PROTON_LOG=1
export PROTON_LOG_DIR=~/.steam/logs

# Run game from Steam
steam

# Check logs
cat ~/.steam/logs/proton-*.log | tail -100
```

**Solution C**: Check 32-bit support is enabled
```bash
# Verify 32-bit graphics library
ldd ~/.steam/steamapps/common/SteamLinuxRuntime*/run/bin/steam 2>&1 | grep "not found"
# Should be empty (no missing libraries)

# If missing libraries shown, ensure:
# In hosts/nixos/nixos-desktop.nix:
hardware.graphics.enable32Bit = true;  # Must be true

nb && nup
```

**Solution D**: Game-specific workarounds
```bash
# Check ProtonDB for known issues
# https://protondb.com/ - search game name

# Try recommended workarounds:
# - Disable DXVK
# - Use specific Wine version
# - Enable/disable esync
# - Modify launch options
```

---

### Error 6: Fullscreen games not working / resolution switching broken

**Symptoms**:
```
Game launches windowed
Can't switch to fullscreen
Resolution wrong
Input doesn't work properly
```

**Causes**:
1. ⚠️ Niri fullscreen window rule missing
2. ⚠️ Gamescope not configured
3. ⚠️ Compositor not supporting fullscreen properly

**Solutions**:

**Solution A**: Add Niri fullscreen window rules
```nix
# Edit modules/nixos/hosts/nixos-desktop/composition.nix
# In window-rules section:

{
  matches = [
    { class = "Wine"; }
    { class = "steam_app_.*"; }
  ];
  allow-fullscreen = true;  # Allow fullscreen
}
```

**Solution B**: Use Gamescope for gaming
```bash
# At login greeter, select "Steam" or "Gamescope" session
# Instead of standard Niri

# Gamescope handles:
# - Fullscreen properly
# - Resolution scaling
# - Nested compositor setup

# Switch back to Niri for desktop work
```

**Solution C**: Force fullscreen in game settings
```bash
# In game settings:
# - Fullscreen: Enabled
# - Resolution: Match monitor resolution
# - V-sync: Can be on or off (test both)
```

---

### Error 7: Audio not working in games

**Symptoms**:
```
Game runs but no sound
Audio works elsewhere (Discord, etc.)
```

**Causes**:
1. ⚠️ PipeWire/audio configuration issue
2. ⚠️ Game audio device selection wrong
3. ⚠️ Audio routing not configured

**Solutions**:

**Solution A**: Check PipeWire is running
```bash
systemctl --user status pipewire
# Should show: active (running)

# If not running:
systemctl --user start pipewire

# Enable on startup:
systemctl --user enable pipewire
```

**Solution B**: Verify audio devices
```bash
# List audio devices
pactl list short sinks
# Should show audio outputs

# Set default device
pactl set-default-sink <device-name>
```

**Solution C**: Check game audio settings
```bash
# In game settings:
# - Audio device: Detected device (not "Default")
# - Volume: Not muted, reasonable level
# - Audio output: Speaker/Headphones
```

**Solution D**: Test audio directly
```bash
# Test PipeWire audio
paplay /usr/share/sounds/freedesktop/stereo/complete.oga
# Should hear sound

# If audio works here but not in game, it's game configuration
```

---

### Error 8: Input lag or controller not recognized

**Symptoms**:
```
Mouse/keyboard unresponsive
Game controller not detected
High input latency
```

**Causes**:
1. ⚠️ XWayland input lag (normal)
2. ⚠️ Controller not mapped properly
3. ❌ Missing input device rules

**Solutions**:

**Solution A**: Reduce XWayland input lag
```bash
# XWayland input lag is normal but can be reduced:
# - Keep game in fullscreen
# - Use Gamescope session (better input handling)
# - Close unnecessary background apps
```

**Solution B**: Configure controller mapping
```bash
# Use community tools:
# - AntiMicroX (GUI controller mapper)
# - Steam Input (built-in, if supported)

# For AntiMicroX:
antimicrox
# Configure button mappings as needed
```

**Solution C**: Check input device permissions
```bash
# Verify input device access
ls -l /dev/input/
# User should have access to /dev/input/event*

# If permission denied:
# Add user to input group (already done in AGENTS.md)
groups michael  # Should show 'input' group
```

---

### Error 9: Screen tearing or stuttering

**Symptoms**:
```
Visual tearing on screen
Stuttering during gameplay
Frames dropping
```

**Causes**:
1. ⚠️ V-sync not enabled
2. ⚠️ Compositor v-sync not working
3. ⚠️ CPU/GPU bottleneck

**Solutions**:

**Solution A**: Enable V-sync in game
```bash
# Game settings:
# V-sync: Enabled
# Target frame rate: 120 (your monitor refresh rate)
```

**Solution B**: Check compositor v-sync
```bash
# Niri has built-in v-sync, usually enabled by default
# No action needed

# For Gamescope:
export GAMESCOPE_VSYNC=1
# Then run game
```

**Solution C**: Monitor performance
```bash
# Enable MangoHUD to see metrics
export MANGOHUD=1

# Identify if GPU or CPU is limiting:
# - GPU utilization ~100%, FPS = monitor refresh rate: V-sync working
# - GPU utilization <100%, FPS <monitor refresh rate: CPU bottleneck
# - V-sync enabled but tearing: Driver issue (unlikely on Proton)
```

**Solution D**: Performance optimization
```bash
# Reduce settings:
# - Graphics quality
# - Resolution
# - Draw distance
# - Particle effects

# Enable performance overlays:
export DXVK_HUD=fps  # DXVK games
export VKD3D_DEBUG=fps  # DX12 games
```

---

### Error 10: Steam achievements/cloud save not working

**Symptoms**:
```
Achievements not unlocking
Cloud saves not syncing
Files not uploading to Steam cloud
```

**Causes**:
1. ⚠️ Network connectivity issue
2. ⚠️ Steam account permissions
3. ⚠️ Game/Proton compatibility

**Solutions**:

**Solution A**: Verify network connectivity
```bash
# Check internet connection
ping 8.8.8.8
# Should show responses

# Check Steam can reach servers
curl -I https://steampowered.com
# Should show HTTP 200
```

**Solution B**: Check Steam settings
```bash
# In Steam:
# Settings → Cloud → Check "Enable Steam Cloud"

# Check game settings:
# Game properties → General → "Keep saves on server"
```

**Solution C**: Verify game compatibility
```bash
# Check ProtonDB for known cloud issues
# https://protondb.com/

# Some games have compatibility flags
# Game properties → Compatibility → 
# Try different Proton version
```

**Solution D**: Manual cloud sync
```bash
# If automatic sync fails, try restarting Steam:
pkill steam
sleep 2
steam &

# Wait for cloud to resync
```

---

## Diagnostic Information Collection

For support requests, collect this information:

```bash
#!/bin/bash
# Run this to collect diagnostic data

echo "=== System Info ==="
uname -a
echo "=== GPU Info ==="
lspci | grep -i vga
nvidia-smi
echo "=== X11 Info ==="
echo "DISPLAY=$DISPLAY"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
xdpyinfo 2>&1 | head -20
echo "=== Steam Info ==="
which steam
steam --version
echo "=== Niri Info ==="
ps aux | grep -i "niri\|xwayland"
echo "=== Environment ==="
env | grep -E "SDL|DISPLAY|DBUS|PROTON|STEAM"
echo "=== Recent Steam Logs ==="
tail -50 ~/.steam/steam/logs/bootstrap.log
```

Save output to file:
```bash
bash diagnostic.sh > steam-diagnostic.log 2>&1
```

Share the log file when asking for support.

---

## Quick Reference: Common Commands

```bash
# Start Steam with debugging
PROTON_LOG=1 steam

# Start game directly with Proton
STEAM_COMPAT_TOOL_PATHS=/var/lib/steam proton run /path/to/game.exe

# Test X11 access
xdpyinfo

# Check GPU rendering
glxinfo | grep "direct rendering"

# Monitor performance
MANGOHUD=1 steam

# Clear Steam cache
rm -rf ~/.cache/steam-overlay ~/.cache/shader-cache

# Check Proton status
ls ~/.steam/steam/compatibilitytools.d/

# View Proton logs
cat ~/.steam/steam/compatdata/*/pfx/drive_c/windows/temp/

# Enable Steam developer mode
echo '{"DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING": true}' > ~/.config/steam/settings.json
```

