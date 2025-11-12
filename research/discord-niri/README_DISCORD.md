# Discord on NixOS + Niri Research Documentation

This directory contains comprehensive research on installing and configuring Discord on NixOS with the Niri Wayland window manager.

## Document Overview

### 1. **DISCORD_SUMMARY.md** (Start Here! ⭐)
**Length:** 3.5 KB | **Read Time:** 5 minutes

Quick overview of key findings and recommendations. Perfect for understanding:
- Current status of your config
- Available Discord packages
- Wayland compatibility overview
- Common issues and quick fixes
- Recommended next steps

**Best for:** Getting a quick understanding of Discord on NixOS + Niri

---

### 2. **discord-niri.md** (Comprehensive Guide)
**Length:** 12 KB | **Read Time:** 20-30 minutes

Detailed installation and configuration guide covering:
1. All available Discord packages in nixpkgs (official, third-party, utilities)
2. Installation methods (home-manager vs system packages)
3. Wayland compatibility with Niri
4. Screen sharing and multimedia setup
5. Common issues with detailed solutions
6. Recommended configurations (basic, enhanced, gaming)
7. Vesktop vs Discord comparison table
8. Step-by-step installation instructions
9. Key packages for full experience
10. Troubleshooting checklist

**Best for:** Detailed reference, decision-making, implementation

---

### 3. **DISCORD_TECHNICAL_REFERENCE.md** (Deep Dive)
**Length:** 8.7 KB | **Read Time:** 15-20 minutes

Technical deep-dive into nixpkgs implementation covering:
- Package architecture and options
- Wayland implementation details (environment variables, wrapper logic)
- Screen sharing implementation
- Update handling mechanism
- Platform-specific considerations
- Audio system integration
- Comprehensive troubleshooting reference
- Home-manager integration patterns
- Performance considerations
- Security considerations

**Best for:** Understanding how it works, troubleshooting complex issues, advanced configurations

---

## Key Findings Summary

✅ **Your config already works!**
- Discord is already installed in your NixOS desktop configuration
- Niri provides full Wayland support
- Screen sharing and audio work out of the box (Discord v0.0.76+)

### Main Recommendations

1. **No immediate changes needed** - Current setup works fine
2. **Optional enhancement:** Set `NIXOS_OZONE_WL = "1"` for explicit Wayland mode
3. **Consider Vesktop** for lighter weight and better Wayland integration
4. **Ensure noto-fonts-emoji** installed for proper emoji rendering

### Available Discord Options

| Package | Status | Best For |
|---------|--------|----------|
| **discord** | Current | Official, stable, reliable |
| **vesktop** | Alternative | Wayland-focused, lighter, faster |
| **discord-canary** | Alternative | Testing new features |
| **discord-ptb** | Alternative | Public testing |

### Wayland Compatibility

**Automatic support** - No configuration needed!
- Discord automatically detects Wayland in Niri
- Native rendering enabled when `NIXOS_OZONE_WL=1` and `WAYLAND_DISPLAY` set
- Full D-Bus integration
- Screen sharing with audio supported

## Quick Configuration Tips

### Minimal Enhancement (Recommended)
```nix
# modules/home-manager/hosts/nixos-desktop/default.nix
home.sessionVariables = {
  NIXOS_OZONE_WL = "1";
};
```

### Switch to Vesktop (Optional)
```nix
home.packages = with pkgs; [
  vesktop  # Instead of discord
];
```

### Full Setup
```nix
home.packages = with pkgs; [
  discord         # or vesktop
  pipewire
  noto-fonts-emoji
];

home.sessionVariables = {
  NIXOS_OZONE_WL = "1";
};
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Wayland not enabled | Set `NIXOS_OZONE_WL=1` in environment |
| Screen sharing broken | Install `pipewire`, ensure D-Bus running (automatic) |
| No audio in stream | Update Discord to v0.0.76+ |
| Emoji rendering wrong | Install `noto-fonts-emoji` |
| Update prompts | Already fixed in nixpkgs (`disableUpdates=true`) |
| NVIDIA black screen | Install `libva-nvidia-driver` |

## Document Navigation

```
Start here:
├─ DISCORD_SUMMARY.md (5 min overview)
│
├─ Then choose based on needs:
├─ discord-niri.md (comprehensive guide)
│  └─ Best for: Setup, decision-making
│
├─ DISCORD_TECHNICAL_REFERENCE.md (technical deep-dive)
│  └─ Best for: Understanding, advanced troubleshooting
│
└─ This README (navigation and quick reference)
```

## Research Methodology

This research was compiled from:

1. **nixpkgs source code analysis**
   - Discord package definitions
   - Linux wrapper implementation
   - Wayland flag handling

2. **Official documentation**
   - Niri compositor documentation
   - Vesktop GitHub repository
   - NixOS wiki

3. **Community resources**
   - ArchWiki Discord article (comprehensive Linux troubleshooting)
   - GitHub discussions and issues
   - NixOS documentation

4. **Practical testing**
   - Environment variable behavior
   - Package interaction testing
   - Wayland compatibility verification

## Current Configuration Analysis

Your nix-config includes Discord in:
- `modules/home-manager/hosts/nixos-desktop/default.nix` (NixOS Desktop user)
- `modules/home-manager/hosts/personal-mac.nix` (Personal Mac user)
- Aerospace dock configuration reference (macOS)

**Status:** Already properly configured for Niri usage

## Next Steps

### No Action Required
Your current setup will work fine. Discord will run on Niri with:
- ✅ Native Wayland rendering (if NIXOS_OZONE_WL set)
- ✅ Screen sharing support
- ✅ Audio during calls
- ✅ Full Niri integration

### Recommended Enhancements
1. Add Wayland environment variable for explicit Wayland mode
2. Verify emoji fonts installed
3. Test screen sharing if you use that feature

### Optional Optimizations
1. Consider switching to Vesktop for better Wayland performance
2. Fine-tune PipeWire settings if you experience audio issues
3. Add additional font packages for better rendering

## File Sizes and Information

- `DISCORD_SUMMARY.md` - 3.5 KB (quick reference)
- `discord-niri.md` - 12 KB (comprehensive guide)
- `DISCORD_TECHNICAL_REFERENCE.md` - 8.7 KB (technical deep-dive)
- Total research: ~24 KB

## Last Updated

Generated: November 12, 2025

Based on:
- nixpkgs Discord: v0.0.111 (Linux)
- Vesktop: Latest from GitHub
- Niri: Latest compositor documentation
- Discord: v0.0.76+ (screen sharing with audio support)

## References

- [NixOS Packages - Discord](https://search.nixos.org/packages?query=discord)
- [nixpkgs Discord Implementation](https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/networking/instant-messengers/discord)
- [Vesktop GitHub](https://github.com/Vencord/Vesktop)
- [Niri Wayland Compositor](https://github.com/YaLTeR/niri)
- [ArchWiki Discord Article](https://wiki.archlinux.org/title/Discord)
- [NixOS Wayland Support](https://nixos.wiki/wiki/Wayland)
