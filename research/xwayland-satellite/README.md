# XWayland-Satellite Research

## Overview

xwayland-satellite is a standalone Xwayland integration tool that runs as a separate process rather than being built into the compositor. It's specifically recommended by Niri for handling X11 application support on Wayland.

**Status in Niri:** Since v25.08, Niri has built-in integration with xwayland-satellite, making it the recommended approach over previous custom configurations.

## Key Resources

- [Niri Xwayland Wiki](https://raw.githubusercontent.com/YaLTeR/niri/main/docs/wiki/Xwayland.md) - Official recommendation
- [xwayland-satellite Repository](https://github.com/Supreeeme/xwayland-satellite) - Main project
- [Niri Integration PR #1728](https://github.com/YaLTeR/niri/pull/1728/files) - Implementation details
- [NixOS nixpkgs](https://search.nixos.org/packages?query=xwayland-satellite) - Package availability

## Quick Facts

| Aspect | Details |
|--------|---------|
| **Latest Version** | 0.7 (as of Nov 2024) |
| **NixOS Package** | `legacyPackages.x86_64-linux.xwayland-satellite` |
| **License** | MPL-2.0 |
| **Language** | Rust |
| **Dependencies** | Xwayland >=23.1, xcb, xcb-util-cursor, clang (build-only) |
| **Niri Integration** | Since v25.08 (automatic) |

---

## What is xwayland-satellite?

### Definition

xwayland-satellite is a **rootless Xwayland integration tool** that grants X11 support to any Wayland compositor implementing:
- `xdg_wm_base` and `viewporter` protocols (core requirements)
- Optional: Linux dmabuf, XDG activation, XDG foreign, pointer constraints, tablet input, fractional scale

### How It Works

1. **Runs as a separate process** (unlike traditional Xwayland built into compositors)
2. **Acts as a Wayland client AND a Wayland compositor** simultaneously
3. **Manages X11 sockets** on disk and exports `$DISPLAY`
4. **Spawns Xwayland on-demand** when X11 clients connect
5. **Automatically restarts Xwayland** if it crashes
6. **Presents X11 windows as normal Wayland windows** to the host compositor

### Architecture Overview

```
┌─────────────────────────────────────────┐
│         Niri (Wayland Compositor)       │
│  - Manages windows as Wayland surfaces  │
└─────────────────┬───────────────────────┘
                  │
         (Wayland client)
                  │
┌─────────────────▼───────────────────────┐
│  xwayland-satellite (Wayland Client)    │
│  - Runs as separate process             │
│  - Acts as Xwayland compositor          │
│  - Manages X11 sockets                  │
└─────────────────┬───────────────────────┘
                  │
         (X11 protocol)
                  │
┌─────────────────▼───────────────────────┐
│      Xwayland (X11 Server)              │
│  - Converts X11 to Wayland              │
└─────────────────┬───────────────────────┘
                  │
         (X11 protocol)
                  │
       ┌──────────┴──────────┐
       ▼                     ▼
   [X11 Apps]           [X11 Apps]
  (Steam, etc)         (Legacy tools)
```

---

## Differences from Regular Xwayland

### Traditional Xwayland (Built-in)
- **Integrated into compositor** (e.g., Mutter, wlroots-based compositors)
- **Requires compositor recompilation** to modify X11 support
- **Complex to manage** within compositor codebase
- **Harder to debug** (mixed concerns)
- **Limited flexibility** for custom configurations

### xwayland-satellite
- **Standalone process** (separate from compositor)
- **No compositor changes needed** - works as external process
- **Simpler architecture** - clear separation of concerns
- **On-demand spawning** - Xwayland only runs when needed
- **Automatic restart** on crash
- **Better debugging** - independent process management
- **Protocol-agnostic** - works with any compositor supporting required protocols
- **Systemd integration** - can be managed as user service

### Why Niri Recommends It

From Niri documentation:
> "We're using xwayland-satellite rather than Xwayland directly because **X11 is very cursed**. xwayland-satellite takes on the bulk of the work dealing with the X11 peculiarities from us, giving niri normal Wayland windows to manage."

**Key Benefits for Niri:**
1. **Reduces complexity** - X11 handling outsourced to satellite
2. **Cleaner codebase** - Niri focuses on Wayland only
3. **Reliability** - Proven track record with multiple compositors
4. **Maintenance** - Shared responsibility with xwayland-satellite maintainers
5. **Flexibility** - Easy to swap or upgrade independently

---

## How It Differs from Other Approaches

### Option 1: xwayland-satellite (Recommended by Niri ✅)
- **Pros:** Automatic, on-demand, restart on crash, seamless integration
- **Cons:** Requires xwayland-satellite package
- **Best for:** Normal usage with X11 apps

### Option 2: Rootful Xwayland (Direct)
- **Pros:** Direct control, simple setup
- **Cons:** Doesn't share clipboard, requires X11 window manager inside, window re-opens on app close
- **Best for:** Gaming, isolated X11 environments

### Option 3: Nested Compositors (Labwc, Cage)
- **Pros:** Full X11 support, window positioning works correctly
- **Cons:** Extra resource overhead, more complex setup
- **Best for:** Apps that require specific window positioning

### Option 4: Gamescope
- **Pros:** Optimized for gaming
- **Cons:** Only shows topmost window, not suitable for regular apps
- **Best for:** Steam games specifically

---

## Niri's Built-in Integration (Since v25.08)

### Automatic Behavior

When xwayland-satellite is installed and available in `$PATH`:

1. **Niri automatically:**
   - Creates X11 sockets on disk
   - Exports `$DISPLAY` environment variable
   - Spawns xwayland-satellite on-demand
   - Restarts if satellite crashes
   - Logs: `listening on X11 socket: :0`

2. **No configuration needed** - it "just works"

3. **Manual configs should be removed** - disable any custom xwayland-satellite start scripts

### Verification

Check that integration is working:

```bash
# Should show X11 socket in logs
journalctl --user-unit=niri -b | grep "X11 socket"

# Output should show:
# INFO niri: listening on X11 socket: :0

# Verify DISPLAY is set
echo $DISPLAY
# Should output: :0

# Check X11 socket exists
ls -la /run/user/$(id -u)/niri/x11/:0
```

---

## NixOS Configuration

### 1. Package Installation

**Option A: System-wide (Recommended)**

```nix
# hosts/nixos/nixos-desktop.nix
environment.systemPackages = with pkgs; [
  xwayland-satellite  # ← Add this
  xwayland            # Still needed for satellite
];
```

**Option B: User-level via Home Manager**

```nix
# modules/home-manager/programs/default.nix
home.packages = with pkgs; [
  xwayland-satellite
];
```

### 2. Verify Package Availability

```bash
# Check version
nix search nixpkgs xwayland-satellite

# Should output:
# legacyPackages.x86_64-linux.xwayland-satellite (0.7)
```

### 3. No Service Configuration Needed

Unlike older approaches, **Niri handles everything automatically**:

- ✅ Niri spawns xwayland-satellite on-demand
- ✅ No systemd service unit needed
- ✅ No manual `$DISPLAY` export needed
- ✅ No custom startup scripts needed

### 4. Environment Variables

**For Niri (handled automatically):**
- `DISPLAY` - Set by Niri to `:0`
- X11 socket path - Managed by Niri

**For X11 Applications (optional):**
- `_JAVA_AWT_WM_NONREPARENTING=1` - Fix blank screens in Java apps
- `XSETTINGS_*` - For scaling/HiDPI (automatic via satellite)

### 5. Optional: Systemd User Service (Legacy)

If using older Niri version (<25.08) or custom setup:

```nix
# modules/home-manager/programs/default.nix

systemd.user.services.xwayland-satellite = {
  Unit = {
    Description = "XWayland Satellite";
    After = [ "graphical-session.target" ];
    PartOf = [ "graphical-session.target" ];
  };
  
  Service = {
    Type = "notify";
    ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :0";
    Restart = "always";
    Environment = [ "DISPLAY=:0" ];
  };
  
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};
```

⚠️ **Note:** Not recommended with Niri 25.08+ - use automatic integration instead.

---

## Integration with Niri

### Automatic Integration Details

**How Niri Integrates (v25.08+):**

1. Niri detects xwayland-satellite in `$PATH`
2. Creates X11 socket directory
3. Passes `-listenfd` argument to Xwayland via satellite
4. Manages socket lifecycle
5. Auto-restarts on failure

**Reference Implementation:**
See [Niri PR #1728](https://github.com/YaLTeR/niri/pull/1728/files) for exact code.

### X11 Applications Working with Niri

**Steam (Works well):**
```bash
# Steam runs natively with X11 support
steam

# Or with Proton games:
PROTON_ENABLE_WAYLAND=1 steam  # Use native Wayland (experimental)
```

**Discord/Vesktop (Works):**
```bash
vesktop
```

**Wine Applications (Works):**
```bash
wine notepad.exe
```

**Java Applications (May need env var):**
```bash
_JAVA_AWT_WM_NONREPARENTING=1 java-app
```

### Window Rules for X11 Apps

**In Niri config** (`modules/nixos/hosts/nixos-desktop/composition.nix`):

```nix
programs.niri.settings = {
  window-rules = [
    # Steam windows
    {
      matches = [
        { app-id = "^steam$"; }
        { title = "^Steam$"; }
      ];
      default-column-width.proportion = 0.5;
    }
    
    # Steam games - allow fullscreen
    {
      matches = [
        { app-id = "^steam_app_.*"; }
      ];
      open-fullscreen = true;
    }
  ];
};
```

### Debugging

**Check if xwayland-satellite is running:**
```bash
ps aux | grep xwayland-satellite
```

**View Niri logs:**
```bash
journalctl --user-unit=niri -n 50  # Last 50 lines
journalctl --user-unit=niri -f     # Follow logs
```

**Test X11 connection:**
```bash
env DISPLAY=:0 xdpyinfo
```

---

## Benefits of xwayland-satellite for Niri Users

### 1. **Automatic Integration**
- No manual configuration required
- Works out-of-the-box in Niri 25.08+
- No custom scripts or services needed

### 2. **On-Demand Spawning**
- Xwayland only runs when X11 app connects
- Saves CPU/memory when not needed
- Automatic restart on crash

### 3. **Cleaner Architecture**
- Separates X11 handling from Niri code
- Easier to maintain and debug
- Protocol-based compatibility (works with any compatible compositor)

### 4. **Better Compatibility**
- Works with Steam, Discord, Wine, etc.
- Handles X11 quirks externally
- Flexible for custom configurations

### 5. **Scaling Support**
- Automatic HiDPI scaling for GTK/Qt apps
- Acts as Xsettings manager
- Handles fractional scaling

### 6. **Reliability**
- Proven in production across multiple compositors
- 693 GitHub stars (as of Nov 2024)
- Active maintenance

---

## Known Limitations

### Application Window Positioning
X11 apps that want to position windows at specific screen coordinates won't behave correctly with xwayland-satellite. They need a nested compositor to run (Labwc, Cage, Gamescope).

**Example problematic apps:**
- Custom bar applications
- Some kiosk applications
- Apps that require exact positioning

**Solution:**
Use one of the nested compositor approaches (see Niri wiki for details).

### HiDPI Mixed-Monitor Setup
With multiple monitors at different DPI settings, xwayland-satellite chooses the smallest monitor's DPI, which may result in small text on other monitors.

**Workaround:**
- Manually set `XSETTINGS` variables
- Use `xsettingsd` for custom scaling

### Java Application Blank Screen
Some Java applications display as blank by default.

**Fix:**
```bash
_JAVA_AWT_WM_NONREPARENTING=1 java-app
```

---

## Current Codebase Status

### Existing Configuration

The project already has xwayland in system packages but not xwayland-satellite:

**Current** (`hosts/nixos/nixos-desktop.nix`):
```nix
environment.systemPackages = with pkgs; [
  # ...
  xwayland          # ← Has this
  xorg.xhost
  xorg.xdpyinfo
];
```

**Recommended upgrade:**
```nix
environment.systemPackages = with pkgs; [
  xwayland-satellite  # ← Add this (handles Xwayland automatically)
  xwayland           # Keep for satellite dependency
  xorg.xhost
  xorg.xdpyinfo
];
```

### Niri Composition Already Set Up

The `modules/nixos/hosts/nixos-desktop/composition.nix` already has excellent Niri configuration including window rules for Steam and games.

---

## Recommended Action Items

### For Current Setup

1. **Add xwayland-satellite to system packages**
   - Location: `hosts/nixos/nixos-desktop.nix`
   - Add to `environment.systemPackages`

2. **Rebuild and verify**
   ```bash
   nb  # Build check
   # User applies: nup  # Switch (when ready)
   ```

3. **Verify integration**
   ```bash
   # Check logs show X11 socket
   journalctl --user-unit=niri -b | grep "X11 socket"
   ```

### For Future Enhancement

- Monitor xwayland-satellite version updates
- Consider Java app wrapper for `_JAVA_AWT_WM_NONREPARENTING=1`
- Add notes about nested compositors to documentation

---

## References

- [Niri Xwayland Wiki](https://raw.githubusercontent.com/YaLTeR/niri/main/docs/wiki/Xwayland.md) - Full implementation details
- [xwayland-satellite GitHub](https://github.com/Supreeeme/xwayland-satellite) - Main repository
- [NixOS Package Search](https://search.nixos.org/packages?query=xwayland-satellite)
- [Niri Documentation](https://yalter.github.io/niri/) - Official docs site

---

**Research Date:** November 2024
**Niri Version Referenced:** 25.08+
**xwayland-satellite Version:** 0.7
