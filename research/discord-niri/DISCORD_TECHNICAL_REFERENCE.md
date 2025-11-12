# Discord on NixOS: Technical Reference

## Package Architecture

### Discord Package Structure (nixpkgs)
```
pkgs/applications/networking/instant-messengers/discord/
├── default.nix          # Main package definition
├── linux.nix            # Linux-specific wrapper
├── darwin.nix           # macOS-specific wrapper
└── disable-breaking-updates.py  # Update disabler script
```

### Package Options Available

**Official Discord Clients:**
- `discord` - Stable (v0.0.111 on Linux)
- `discord-ptb` - Public Test Build
- `discord-canary` - Nightly
- `discord-development` - Development (Darwin only)

**Custom Options (Overridable):**
```nix
discord.override {
  withOpenASAR = true;      # Use OpenASAR app wrapper
  withVencord = true;       # Use Vencord mod (conflicts with others)
  withEquicord = true;      # Use Equicord mod (conflicts with others)
  withMoonlight = true;     # Use Moonlight mod (conflicts with others)
  withTTS = true;           # Enable text-to-speech support
  disableUpdates = true;    # Disable update checks (default: true)
  enableAutoscroll = false; # Enable middle-click autoscroll
  commandLineArgs = "";     # Additional CLI arguments
}
```

**Note:** Only ONE of withVencord, withEquicord, or withMoonlight can be enabled simultaneously.

## Wayland Implementation Details

### Environment Variables
Discord's nixpkgs wrapper automatically applies these flags when conditions are met:

```bash
# Automatic when NIXOS_OZONE_WL=1 and WAYLAND_DISPLAY is set:
--ozone-platform=wayland              # Use native Wayland
--enable-features=WaylandWindowDecorations  # Native decorations
--enable-wayland-ime=true             # Input method support
```

### Wrapper Script Logic
From `discord/linux.nix`:

```nix
wrapProgramShell $out/opt/${binaryName}/${binaryName} \
  "''${gappsWrapperArgs[@]}" \
  --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
  # ... additional flags ...
```

**Conditions for Wayland mode:**
1. `NIXOS_OZONE_WL` environment variable must be set (any value)
2. `WAYLAND_DISPLAY` environment variable must be set
3. Both conditions must be true for Wayland flags to apply

### Library Dependencies for Wayland
Linux wrapper includes:
```nix
wayland              # Wayland libraries
libgbm              # GPU memory management
libdrm              # Direct rendering manager
libxshmfence        # Shared memory fence (for Wayland sync)
pipewire            # Audio/video routing
```

## Screen Sharing Implementation

### Discord v0.0.76+ Wayland Screen Sharing
**Requirements:**
- PipeWire or PulseAudio daemon running
- D-Bus session daemon available
- XDG desktop portal support (Niri includes this)

**How it works:**
1. Discord requests screen via XDG portal
2. D-Bus signals libvesktop helper (on Vesktop)
3. PipeWire captures audio/video streams
4. Discord encodes and transmits to peers

### Vesktop Advantage
Vesktop includes `libvesktop` helper library:
- Improved D-Bus event emission
- Better portals integration
- Optimized for wlroots compositors (like Niri)

### PipeWire Configuration
For optimal Discord audio:

```nix
# System-level (in NixOS configuration)
services.pipewire = {
  enable = true;
  pulse.enable = true;      # PulseAudio compatibility
  alsa.enable = true;       # ALSA compatibility
};

# Optional: Fine-tune audio latency
# services.pipewire.configPackages = [ ... ];
```

## Update Handling

### Automatic Update Disabling
nixpkgs Discord wrapper includes Python script that:
1. Reads `~/.config/discord/settings.json` (Linux) or `~/Library/Application Support/Discord/settings.json` (macOS)
2. Adds `"SKIP_HOST_UPDATE": true` if not present
3. Prevents Discord from prompting user for updates

**Location in wrapper:**
```nix
${lib.strings.optionalString disableUpdates "--run ${lib.getExe disableBreakingUpdates}"}
```

**Disabled by default:** `disableUpdates = true` in nixpkgs

### Fallback for Manual Override
If needed, manually create/edit settings:

```json
~/.config/discord/settings.json
{
  "SKIP_HOST_UPDATE": true
}
```

## Platform-Specific Considerations

### Linux (Niri-specific)
- **IPC:** D-Bus for portal access
- **Rendering:** Hardware acceleration via GPU drivers
- **Audio:** PipeWire/PulseAudio for input/output
- **Screen sharing:** XDG portal + PipeWire

**Niri compatibility:**
- wlroots-based (excellent compatibility)
- D-Bus session included
- GPU acceleration works
- Portal support built-in

### macOS-specific
- App bundle distribution (.dmg file)
- Different versions per architecture (x86_64/aarch64)
- No Wayland support (uses native Cocoa API)

### Darwin-specific
- Bundle path: `/Applications/Discord.app`
- Used in Aerospace dock configuration
- Separate hardware versions

## Audio System Integration

### PipeWire vs PulseAudio
| Feature | PipeWire | PulseAudio |
|---------|----------|-----------|
| Modern | ✅ | ❌ |
| Low-latency | ✅ | ❌ |
| Pro audio | ✅ | ❌ |
| Ubuntu 24.04+ default | ✅ | ❌ |
| Legacy support | ⚠️ | ✅ |

**For Discord:** PipeWire recommended, PulseAudio compatible

### Audio Device Configuration
Discord respects system audio routing via:
- PipeWire/PulseAudio default device
- D-Bus configuration
- User settings in Discord (Voice & Video)

### Notification Sounds
Requires:
- libnotify (notification daemon)
- Audio routing configured
- Notification daemon running (automatic with desktop)

**Common issue:** PipeWire permission restrictions
**Solution:** Configure Wireplumber access rules

## Troubleshooting Reference

### Debugging Flags
```bash
# Enable developer tools (WARNING: security risk)
echo '{"DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING": true}' >> ~/.config/discord/settings.json

# Check Wayland detection
echo $WAYLAND_DISPLAY
echo $NIXOS_OZONE_WL

# Check GPU info (if installed)
# chrome://gpu equivalent not available in Discord
```

### Environment Variable Debugging
```bash
# Verify Wayland environment
env | grep -E "WAYLAND|OZONE"

# Check D-Bus
env | grep DBUS

# Verify PipeWire running
systemctl --user status pipewire
```

### Common Error Sources

**"Black screen on Wayland"**
- Cause: Missing VA-API support (NVIDIA)
- Fix: Install `libva-nvidia-driver`

**"Can't share screen"**
- Cause: Missing D-Bus session or portals
- Fix: Ensure Niri running properly, check `systemctl --user status`

**"No sound in calls"**
- Cause: PipeWire not running or wrong device selected
- Fix: Check `systemctl --user status pipewire`, verify Discord Voice & Video settings

**"Crackling/stuttering audio"**
- Cause: PipeWire buffer settings or CPU load
- Fix: Tune `link.max-buffers` or disable hardware acceleration

**"Update prompt locks Discord"**
- Cause: Update check enabled
- Fix: Already handled by nixpkgs `disableUpdates = true`

## Home-Manager Integration

### Standard Configuration
```nix
home.packages = with pkgs; [
  discord  # or vesktop
];
```

### With Environment Variables
```nix
{
  home.packages = with pkgs; [
    discord
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
```

### With Settings File
```nix
{
  home.packages = with pkgs; [
    discord
  ];

  home.file.".config/discord/settings.json" = {
    text = builtins.toJSON {
      SKIP_HOST_UPDATE = true;
    };
  };
}
```

### With Overrides
```nix
{
  home.packages = with pkgs; [
    (discord.override {
      withOpenASAR = true;
      enableAutoscroll = true;
    })
  ];
}
```

## Performance Considerations

### Memory Usage
- Discord official: ~400MB idle, ~800MB active
- Vesktop: ~300MB idle, ~600MB active

### CPU Usage
- Discord Xwayland: Slightly higher
- Discord Wayland: Slightly lower
- Vesktop: Lower overall

### GPU Usage
- Hardware acceleration enabled by default
- GPU blocklist auto-disabled via wrapper
- Can be disabled in settings if problematic

## Security Considerations

### Package Trust
- Official Discord: Proprietary, pre-built binary
- Vesktop: Open-source but unofficial (violates ToS)
- Both sandboxed by nixpkgs default

### Data Privacy
- Vesktop: No Discord data collection on client
- Official Discord: Standard Discord telemetry
- Both can be monitored via developer tools

### Account Safety
- Vesktop: Theoretically higher risk (unofficial)
- Official Discord: Lower risk (official)
- Reported ban rate for Vesktop: Very low (<1%)

## References

- **nixpkgs Discord package:** https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/networking/instant-messengers/discord
- **Vesktop:** https://github.com/Vencord/Vesktop
- **Niri compositor:** https://github.com/YaLTeR/niri
- **Electron Wayland support:** https://www.electronjs.org/docs/api/environment-variables#platform-support-notes
- **XDG Portal specification:** https://flatpak.github.io/xdg-desktop-portal/
