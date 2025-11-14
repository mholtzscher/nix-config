# Steam on NixOS with Niri: Documentation Index

## 📚 Documentation Structure

```
research/steam-niri/
├── README.md                      # Overview and current configuration analysis
├── INDEX.md                       # This file - navigation guide
├── QUICK_START.md                 # 5-minute implementation guide ⭐ START HERE
├── CONFIGURATION_FIX.md            # Detailed step-by-step fixes
├── TECHNICAL_REFERENCE.md          # Deep technical explanation (1000+ lines)
└── TROUBLESHOOTING.md              # Error solutions (10 common errors)
```

## 🎯 Choose Your Path

### I Just Want It to Work ⚡
1. Read **QUICK_START.md** (5 minutes)
2. Apply the 3 fixes
3. Run `nup`
4. Done!

### I Want to Understand What's Happening 🧠
1. Read **README.md** (overview)
2. Read **TECHNICAL_REFERENCE.md** (architecture)
3. Review **CONFIGURATION_FIX.md** (implementation details)

### Something's Broken 🔧
1. Search **TROUBLESHOOTING.md** for your error
2. Follow diagnostic steps
3. Try solutions in order
4. If still broken, collect diagnostic info

### I'm Building This for the First Time 🏗️
1. Start with **README.md** (understand the problem)
2. Read **CONFIGURATION_FIX.md** (complete walkthrough)
3. Apply changes following the exact file paths
4. Test with checklist at end of QUICK_START.md

---

## 📖 Document Summary

### README.md
- **Purpose**: Overview and current configuration analysis
- **Length**: ~200 lines
- **Best for**: Understanding the problem space
- **Key sections**:
  - Quick fix summary
  - Current configuration analysis
  - Known issues
  - Architecture overview

### QUICK_START.md ⭐
- **Purpose**: Fast implementation (5 minutes)
- **Length**: ~300 lines
- **Best for**: Users who just want Steam working
- **Key sections**:
  - 3 critical fixes
  - Apply changes procedure
  - Common errors & quick fixes
  - Verification checklist

### CONFIGURATION_FIX.md
- **Purpose**: Detailed step-by-step fixes with explanations
- **Length**: ~400 lines
- **Best for**: Understanding exactly what to change and why
- **Key sections**:
  - Issue 1-4: Each problem explained
  - Complete fixed configuration
  - Validation steps
  - Testing procedures

### TECHNICAL_REFERENCE.md
- **Purpose**: Deep technical implementation
- **Length**: ~1000 lines
- **Best for**: Understanding internals and advanced configuration
- **Key sections**:
  - Understanding the X error
  - Niri's XWayland support
  - NixOS Steam module
  - Environment variables explained
  - Graphics stack integration
  - Gamescope compositor
  - Proton configuration
  - Performance tuning

### TROUBLESHOOTING.md
- **Purpose**: Common errors and solutions
- **Length**: ~1200 lines
- **Best for**: Debugging specific issues
- **Key sections**:
  - 10 common errors with solutions
  - Diagnostic information collection
  - Quick reference commands

---

## 🔍 Finding Information

### By Topic

**"I need to add XWayland"**
- → QUICK_START.md: Fix 1
- → CONFIGURATION_FIX.md: Issue 1
- → TECHNICAL_REFERENCE.md: Section 6

**"SDL_VIDEODRIVER is conflicting"**
- → QUICK_START.md: Fix 2
- → TROUBLESHOOTING.md: Error 2
- → TECHNICAL_REFERENCE.md: Section 4

**"My DISPLAY variable is wrong"**
- → TROUBLESHOOTING.md: Error 1
- → TECHNICAL_REFERENCE.md: Section 4 (DISPLAY)
- → QUICK_START.md: "Still Not Working?"

**"Games won't go fullscreen"**
- → QUICK_START.md: Fix 3
- → TROUBLESHOOTING.md: Error 6
- → TECHNICAL_REFERENCE.md: Section 7

**"Steam has a black screen"**
- → TROUBLESHOOTING.md: Error 3
- → TECHNICAL_REFERENCE.md: Section 5 (Graphics)

**"GPU acceleration isn't working"**
- → TROUBLESHOOTING.md: Error 3
- → TECHNICAL_REFERENCE.md: Section 5

**"I want to use Gamescope"**
- → TECHNICAL_REFERENCE.md: Section 8
- → QUICK_START.md: "Advanced: Using Gamescope"
- → README.md: Architecture overview

### By Error Type

| Error | Document | Section |
|-------|----------|---------|
| "Unable to open connection to X" | TROUBLESHOOTING.md | Error 1 |
| "SDL_VideoModeOK failed" | TROUBLESHOOTING.md | Error 2 |
| Black screen | TROUBLESHOOTING.md | Error 3 |
| Steam freezes | TROUBLESHOOTING.md | Error 4 |
| Game crashes | TROUBLESHOOTING.md | Error 5 |
| Fullscreen broken | TROUBLESHOOTING.md | Error 6 |
| No audio | TROUBLESHOOTING.md | Error 7 |
| Input lag | TROUBLESHOOTING.md | Error 8 |
| Screen tearing | TROUBLESHOOTING.md | Error 9 |
| Achievements not working | TROUBLESHOOTING.md | Error 10 |

---

## 🚀 Quick Navigation

### First Time Setup
```
README.md → QUICK_START.md → CONFIGURATION_FIX.md → Apply Changes → Test
```

### Troubleshooting
```
Identify Error → TROUBLESHOOTING.md → Find Error → Follow Solutions
```

### Deep Dive Learning
```
README.md → TECHNICAL_REFERENCE.md → Sections 1-7 → Experiment
```

### Advanced Configuration
```
TECHNICAL_REFERENCE.md → Sections 8-10 (Gamescope, Proton, Tuning)
```

---

## 📋 Checklist by Use Case

### Use Case: Basic Steam Installation ✅
- [ ] Read QUICK_START.md
- [ ] Apply Fix 1: Add XWayland
- [ ] Apply Fix 2: Remove SDL_VIDEODRIVER
- [ ] Apply Fix 3: Add window rules
- [ ] Run `nix flake check`
- [ ] Run `nb`
- [ ] Run `nup`
- [ ] Verify with checklist

### Use Case: Gaming Optimization 🎮
- [ ] Complete Basic Installation
- [ ] Read TECHNICAL_REFERENCE.md Sections 8-10
- [ ] Configure MangoHud (already done)
- [ ] Configure GameMode (already done)
- [ ] Optional: Set up Gamescope
- [ ] Test performance with `MANGOHUD=1 steam`

### Use Case: Fixing Specific Error 🔧
- [ ] Identify error message
- [ ] Search TROUBLESHOOTING.md
- [ ] Follow diagnostic steps
- [ ] Apply Solution A, B, C in order
- [ ] If still broken, collect diagnostic info
- [ ] Review TECHNICAL_REFERENCE.md section for that topic

### Use Case: Understanding Architecture 🏗️
- [ ] Read README.md overview
- [ ] Read TECHNICAL_REFERENCE.md Sections 1-3
- [ ] Read CONFIGURATION_FIX.md (not the code, the explanations)
- [ ] Review TECHNICAL_REFERENCE.md Section 7 (Niri integration)

---

## 📞 Support Reference

### Quick Diagnostics
```bash
# Run this to check system status
echo "=== XWayland ===" && which xwayland
echo "=== Display ===" && echo $DISPLAY
echo "=== X11 Connection ===" && xdpyinfo | head -5
echo "=== Niri ===" && ps aux | grep niri | grep -v grep
echo "=== Steam ===" && which steam
```

### Detailed Diagnostics
See TROUBLESHOOTING.md section: "Diagnostic Information Collection"

### If You Need Help
1. Run diagnostics above
2. Check your error in TROUBLESHOOTING.md
3. Provide output and error message in support request
4. Reference which document section you're reading

---

## 🔗 Related Documentation

In your nix-config repository:
- **discord-niri/** - Similar Wayland integration patterns (D-Bus, environment variables)
- **AGENTS.md** - Nix configuration guidelines and safety rules

External references:
- [Niri GitHub](https://github.com/YaLTeR/niri)
- [Gamescope GitHub](https://github.com/ValveSoftware/gamescope)
- [NixOS Steam Module](https://search.nixos.org/options?query=steam)
- [Proton GitHub](https://github.com/ValveSoftware/Proton)
- [ProtonDB](https://protondb.com)

---

## 📝 Key Takeaways

### Main Issues in Your Config
1. **Missing XWayland** - X11 clients can't run without it
2. **SDL conflict** - `SDL_VIDEODRIVER=wayland` breaks Steam launcher
3. **Hardcoded DISPLAY** - Overrides Niri's detection
4. **No window rules** - Niri doesn't know how to manage X11 windows

### Main Fixes
1. **Add `xwayland` to systemPackages**
2. **Remove `SDL_VIDEODRIVER=wayland`**
3. **Remove hardcoded `DISPLAY=:0`**
4. **Add Steam window rules to Niri config**

### Why It Matters
- Steam launcher = X11 app (needs XWayland bridge)
- Games = often use X11 (via Proton/Wine)
- Wayland = can't run X11 apps directly
- XWayland = X11 server that runs on Wayland

### Key Concepts
- **XWayland**: Bridge between X11 and Wayland worlds
- **DISPLAY**: Environment variable pointing to X11 server
- **SDL_VIDEODRIVER**: Graphics driver selection
- **D-Bus**: Inter-process communication (D-Bus)
- **Niri**: Wayland compositor (desktop manager)

---

## 📊 Document Statistics

| Document | Lines | Topics | Sections | Read Time |
|----------|-------|--------|----------|-----------|
| README.md | 200 | 6 | 8 | 5 min |
| QUICK_START.md | 300 | 8 | 12 | 5 min |
| CONFIGURATION_FIX.md | 400 | 10 | 6 | 10 min |
| TECHNICAL_REFERENCE.md | 1000 | 20+ | 12 | 30 min |
| TROUBLESHOOTING.md | 1200 | 15+ | 12 | 45 min |
| **TOTAL** | **3100** | **60+** | **50** | **95 min** |

**Total documentation time**: ~1.5 hours for complete understanding

---

**Version**: 1.0 | **Last Updated**: 2025-11-14
