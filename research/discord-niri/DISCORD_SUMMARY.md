# Discord on NixOS + Niri: Quick Summary

## Key Findings

### 1. Current Status
Your nix-config already includes Discord in:
- **NixOS Desktop**: `modules/home-manager/hosts/nixos-desktop/default.nix`
- **Personal Mac**: `modules/home-manager/hosts/personal-mac.nix`

Discord will work out of the box with Niri.

### 2. Available Packages
- **discord** (recommended, currently used) - Official stable
- **vesktop** (better for Wayland) - Faster, lighter, better screen sharing
- **discord-ptb** - Testing releases
- **discord-canary** - Nightly builds
- **discord-screenaudio** - Stream-focused alternative

### 3. Wayland Compatibility with Niri
✅ **Automatic Wayland support** - No manual configuration needed!

Discord in nixpkgs automatically enables Wayland when:
1. `NIXOS_OZONE_WL` environment variable is set
2. `WAYLAND_DISPLAY` is available (Niri provides this)

Features enabled automatically:
- Native Wayland rendering (`--ozone-platform=wayland`)
- Window decorations
- Input Method Engine (IME) for text input

### 4. Screen Sharing & Audio
✅ **Supported on Discord v0.0.76+**
- Native audio streaming with Wayland
- D-Bus integration for screen selection
- Requires PipeWire or PulseAudio (pre-installed typically)

**Vesktop advantage**: Better integrated support via libvesktop helper library

### 5. Common Issues & Quick Fixes

| Issue | Fix |
|-------|-----|
| Wayland not enabled | Set `home.sessionVariables.NIXOS_OZONE_WL = "1"` |
| Screen sharing broken | Install `pipewire`, ensure D-Bus running (Niri does this) |
| No audio on screen share | Update Discord to v0.0.76+ |
| Emoji rendering issues | Install `noto-fonts-emoji` |
| Update prompts lock you out | Automatic fix in nixpkgs (`disableUpdates = true`) |
| Crackling audio | Tune PipeWire settings or disable hardware accel |
| NVIDIA black screen | Install `libva-nvidia-driver` |

### 6. Recommended Minimal Enhancement

**Current setup works fine, but to optimize for Niri:**

```nix
# modules/home-manager/hosts/nixos-desktop/default.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vesktop  # OR keep discord if preferred
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Ensure Wayland is used
  };
}
```

**Or keep current setup** - Discord already works with Niri out of the box.

### 7. Installation Method
✅ **Home-manager (current approach)**
- User-specific package
- Easiest to manage per-host
- No system-wide impact
- Already configured correctly

### 8. What You Get
With minimal config:
- ✅ Discord runs on Niri with native Wayland rendering
- ✅ Screen sharing works
- ✅ Audio during calls/streams works (v0.0.76+)
- ✅ Emoji rendering works (if noto-fonts-emoji installed)
- ✅ No update prompts locking you out
- ✅ Full D-Bus integration with Niri

### 9. Additional Optional Packages

For best experience:
```nix
home.packages = with pkgs; [
  discord  # or vesktop
  pipewire  # Audio
  noto-fonts-emoji  # Emoji
  
  # Optional
  discord-screenaudio  # Alternative for streaming
];
```

### 10. Next Steps

**No action required** - Your config already works!

If you want to optimize:
1. Add `NIXOS_OZONE_WL = "1"` to `home.sessionVariables`
2. Optionally switch to `vesktop` for better Wayland integration
3. Ensure `noto-fonts-emoji` is in packages for emoji support

## Full Documentation

See `discord-niri.md` for comprehensive guide covering:
- Detailed package comparison
- Screen sharing configuration
- All known issues and solutions
- Advanced configuration options
- Troubleshooting checklist
