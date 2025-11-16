# Shure MV7+ on NixOS - Complete Research Index

**Last Updated:** November 15, 2025  
**Research Scope:** NixOS configurations, audio servers, microphone processing tools  
**Target:** Setting up Shure MV7+ USB microphone with professional effects processing

---

## 📚 Documentation Structure

### 1. **README.md** - Comprehensive Guide
The main reference document covering:
- Audio server setup (PipeWire, Bluetooth)
- Microphone effects & processing tools (EasyEffects, RNNoise, Carla, qpwgraph)
- Configuration patterns for USB microphones
- Graphical tools overview
- Troubleshooting and advanced configurations
- Performance tuning

**Use when:** You need detailed information on any aspect of audio configuration.

### 2. **QUICK_START.md** - Fast Setup
Step-by-step minimal configuration to get up and running:
- System configuration (50 lines)
- Home-manager configuration (10 lines)
- Verification steps
- Common issues & quick fixes

**Use when:** You want to set up a basic working configuration quickly.

### 3. **TOOLS_REFERENCE.md** - Complete Package Reference
Detailed reference for every audio tool available in nixpkgs:
- Audio servers (PipeWire, WirePlumber, PulseAudio)
- Control tools (pavucontrol, qpwgraph, pwvucontrol)
- Effects processors (EasyEffects, RNNoise, Carla)
- ALSA utilities (alsa-utils, pamixer)
- Configuration file locations
- Debugging commands

**Use when:** You need to understand what a specific package does or how to use it.

### 4. **BEST_PRACTICES.md** - Do's and Don'ts
Practical guidelines with DO/DON'T examples:
- Audio server configuration best practices
- Microphone detection & setup patterns
- Effects & processing strategies
- Performance optimization tips
- Testing methodology
- Configuration organization
- Common pitfalls and prevention

**Use when:** You're making configuration decisions and want to avoid common mistakes.

---

## 🎯 Quick Navigation by Task

### Getting Started
1. Read: **QUICK_START.md** (5 minutes)
2. Apply: Minimal system configuration
3. Test: Run verification commands
4. Refer to: **README.md** for troubleshooting if needed

### Understanding Components
- **Audio Servers:** TOOLS_REFERENCE.md → Audio Servers & Routing
- **Effects Tools:** TOOLS_REFERENCE.md → Microphone Effects & Processing
- **Control GUI:** TOOLS_REFERENCE.md → Audio Control & Monitoring
- **Low-level Audio:** TOOLS_REFERENCE.md → ALSA & Low-Level Tools

### Configuring Effects
1. Start with: README.md → Microphone Effects & Processing
2. Test with: EasyEffects GUI (`nix run nixpkgs#easyeffects`)
3. Reference: BEST_PRACTICES.md → Effects & Processing
4. Fine-tune: TOOLS_REFERENCE.md → RNNoise/EasyEffects sections

### Troubleshooting
1. Check: README.md → Troubleshooting section
2. Run: Debugging commands from TOOLS_REFERENCE.md
3. Follow: QUICK_START.md → Troubleshooting Steps
4. Review: BEST_PRACTICES.md → Common Issues & Prevention

### Performance Tuning
1. Read: README.md → Advanced Configurations
2. Apply: Performance Tuning section
3. Reference: BEST_PRACTICES.md → Performance Optimization
4. Monitor: Debugging commands from TOOLS_REFERENCE.md

---

## 🔍 Key Findings Summary

### Audio Server Choice
- **Recommended:** PipeWire with WirePlumber
- **Reason:** Modern, better USB support, lower latency, JACK emulation
- **Fallback:** PulseAudio (legacy, still works)

### Microphone Effects Tools

| Tool | Best For | GUI | Declarative |
|------|----------|-----|-------------|
| **EasyEffects** | Easy setup, real-time adjustment | ✅ | Via presets |
| **RNNoise** | Background noise suppression | ❌ | ✅ via filter-chain |
| **Carla** | Complex routing, VST/LV2 plugins | ✅ | Partially |
| **qpwgraph** | Visual signal flow | ✅ | ❌ (UI-based) |

### Configuration Patterns
- **Pattern Matching:** Use `alsa_input.usb-Shure*` instead of hardcoded names
- **Modular Config:** Separate system vs user-level configuration
- **Filter Chain:** Declarative effect chains via `libpipewire-module-filter-chain`
- **WirePlumber Rules:** Lua-based device configuration

### Required System Settings
```nix
# Minimum config
services.pipewire.enable = true
services.pipewire.alsa.enable = true
services.pipewire.pulse.enable = true
security.rtkit.enable = true
hardware.pulseaudio.enable = false
```

### Essential Packages
```nix
pipewire
wireplumber
alsa-utils
pavucontrol
qpwgraph
easyeffects
```

---

## 📊 Packages & Versions

All versions current as of NixOS unstable (November 2025):

- **PipeWire:** Latest (1.0+)
- **WirePlumber:** 0.4+ (default in 24.05+)
- **EasyEffects:** 7.2.5+
- **qpwgraph:** 0.9.6+
- **RNNoise Plugin:** 1.10+
- **Carla:** Latest
- **pavucontrol:** 6.1+
- **alsa-utils:** Latest

---

## 🔗 Research Sources

### GitHub Repositories (with real configurations found)
- **NixOS/nixpkgs:** PipeWire, EasyEffects, qpwgraph packages
- **nix-community/home-manager:** EasyEffects module, examples
- **JManch/nixos:** Audio configuration patterns
- **hlissner/dotfiles:** EasyEffects + PipeWire integration
- **balsoft/nixos-config:** qpwgraph + audio setup

### NixOS Wiki References
- https://nixos.wiki/wiki/PipeWire (primary reference)
- https://nixos.wiki/wiki/JACK (JACK & audio optimization)
- https://nixos.wiki/wiki/ALSA (low-level audio)
- https://nixos.wiki/wiki/Audio (audio category)

### External Resources
- PipeWire Docs: https://pipewire.pages.freedesktop.org/
- WirePlumber Docs: https://pipewire.pages.freedesktop.org/wireplumber/
- EasyEffects GitHub: https://github.com/wwmm/easyeffects
- RNNoise Project: https://gitlab.xiph.org/xiph/rnnoise

---

## 🎓 Learning Path

### Beginner (1-2 hours)
1. Read: QUICK_START.md
2. Apply: Basic configuration
3. Test: Recording verification
4. Reference: README.md for troubleshooting

### Intermediate (2-4 hours)
1. Read: README.md (full)
2. Explore: TOOLS_REFERENCE.md (audio servers section)
3. Configure: Add EasyEffects
4. Reference: BEST_PRACTICES.md for configuration patterns

### Advanced (4+ hours)
1. Study: All documents
2. Implement: Custom filter chains with RNNoise
3. Reference: Advanced Configurations in README.md
4. Experiment: JACK integration if needed

---

## ✅ Verification Checklist

Use this to verify your setup is working:

- [ ] PipeWire service running: `systemctl --user status pipewire`
- [ ] WirePlumber running: `systemctl --user status wireplumber`
- [ ] MV7+ detected: `lsusb | grep -i shure`
- [ ] ALSA sees device: `arecord -l | grep -i shure`
- [ ] PipeWire sees device: `pw-dump | grep -i usb`
- [ ] Recording works: `arecord -f cd -d 3 test.wav`
- [ ] Playback works: `aplay test.wav`
- [ ] pavucontrol shows device: `pavucontrol` (Input Devices tab)
- [ ] EasyEffects running (if enabled): `systemctl --user status easyeffects`
- [ ] Effects available: EasyEffects GUI → Input tab shows plugins

---

## 🐛 Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| Device not detected | README.md → Troubleshooting → Microphone Not Detected |
| No sound input | README.md → Troubleshooting → No Sound Input |
| PipeWire won't start | README.md → Troubleshooting → PipeWire Won't Start |
| High latency | README.md → Troubleshooting → Latency Issues |
| Permission denied | BEST_PRACTICES.md → Audio Group Setup |
| Effects not working | QUICK_START.md → Troubleshooting Steps |

---

## 💾 Configuration Files

### Location Map

| Purpose | Location | Type | How to Edit |
|---------|----------|------|------------|
| System audio | `/etc/pipewire/` | Symlinks to /nix/store | Via `services.pipewire.extraConfig` |
| Device rules | `/etc/wireplumber/` | Symlinks to /nix/store | Via `services.pipewire.wireplumber.configPackages` |
| User effects | `~/.config/easyeffects/` | JSON | EasyEffects GUI |
| ALSA config | `/etc/asound.conf` | PCM config | Via `environment.etc` |

### Editing Approach
- **System-level:** Modify `configuration.nix` → rebuild
- **User-level:** Use home-manager → rebuild
- **Runtime testing:** Use GUI tools (pavucontrol, easyeffects)
- **Persistent testing:** Save to preset before rebuilding

---

## 🔄 Update & Maintenance

### Updating Configuration
```bash
# When updating from this research:
nix flake update                  # Update inputs
nixos-rebuild build --flake .    # Test configuration
nixos-rebuild switch --flake .   # Apply (if working)
```

### Monitoring Audio System
```bash
# Check for issues:
journalctl --user -u pipewire -f
journalctl --user -u wireplumber -f
journalctl -f | grep -i audio
```

### Backing Up Settings
```bash
# Save EasyEffects presets:
cp -r ~/.config/easyeffects ~/backups/
cp -r ~/.config/qpwgraph ~/backups/

# Version control:
git add . && git commit -m "Audio configuration working"
```

---

## 📝 Notes for This Config

- No Shure MV7+ specific kernel parameters found to be required
- Device works out-of-the-box with standard USB audio support
- RNNoise noise suppression is the most effective background noise solution
- EasyEffects provides GUI while PipeWire filter-chain is declarative
- Low-latency config recommended for real-time communication (calls, streaming)

---

## 🎯 Next Steps

1. **Immediate:** Apply QUICK_START.md configuration
2. **Short-term:** Test and verify with commands in QUICK_START.md
3. **Medium-term:** Add EasyEffects from README.md
4. **Long-term:** Implement advanced filters if needed

---

**For questions or updates:** See README.md → References for external resources.

