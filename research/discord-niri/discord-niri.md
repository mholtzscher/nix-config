# Discord on NixOS with Niri: Installation & Configuration Guide

## 1. Available Discord Packages in nixpkgs

NixOS provides several Discord-related packages:

### Official Discord Clients
- **discord** - Stable release (Linux: 0.0.111, Darwin: 0.0.362)
- **discord-ptb** - Public Test Build (Linux: 0.0.161, Darwin: 0.0.192)
- **discord-canary** - Nightly/Canary builds (Linux: 0.0.761, Darwin: 0.0.867)
- **discord-development** - Development builds (Darwin only)

### Third-Party Alternatives
- **vesktop** - Custom Discord client with Vencord preinstalled
  - Better performance and Linux support
  - Native screen sharing with audio on Wayland
  - Lighter weight than official client
  - Built on Electron with modifications for Linux
  
### Utilities & Mods
- **discord-screenaudio** - Custom client supporting stream audio on Linux
- **discord-rpc** - Rich Presence library
- **discord-rich-presence-plex** - Plex integration
- **discordchatexporter-cli/desktop** - Chat export tools
- **discordo** - Lightweight terminal client (TUI)

## 2. Installation Methods on NixOS

### Option A: Home-Manager Packages (Recommended for users)
Add to `modules/home-manager/hosts/nixos-desktop/default.nix`:

```nix
home.packages = with pkgs; [
  discord  # or vesktop, discord-canary, etc.
];
```

**Pros:**
- User-specific installation
- Easy to manage per-host
- No system-wide impact
- Works without root/sudo

**Cons:**
- Only available to that user
- Each user must install separately if needed

### Option B: System Packages (NixOS)
Add to `modules/nixos/nixos.nix`:

```nix
environment.systemPackages = with pkgs; [
  discord
];
```

**Pros:**
- Available to all users
- Installed at system level

**Cons:**
- Larger system closure
- All users get it whether they want it or not

### Current Configuration Status
Your config already includes Discord in:
- `modules/home-manager/hosts/nixos-desktop/default.nix` (NixOS Desktop user)
- `modules/home-manager/hosts/personal-mac.nix` (Personal Mac user)
- Referenced in macOS Aerospace dock config

## 3. Wayland Compatibility with Niri

### Automatic Wayland Support
Discord on NixOS is pre-configured for Wayland through environment variables:

From discord/linux.nix wrapper:
```nix
--add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
```

**Conditions for Wayland mode:**
1. `NIXOS_OZONE_WL` environment variable must be set
2. `WAYLAND_DISPLAY` must be set (Niri provides this)
3. Automatic native Wayland rendering enabled when both conditions met

### Manual Wayland Enabling
Set environment variables before running Discord:

```bash
export NIXOS_OZONE_WL=1
export WAYLAND_DISPLAY=wayland-1  # or your Niri display
discord
```

### Niri-Specific Considerations
- **Compositor compatibility:** Niri is a wlroots-based Wayland compositor, fully compatible with Discord
- **Window decorations:** Enabled automatically on Wayland via `--enable-features=WaylandWindowDecorations`
- **IME support:** Enabled via `--enable-wayland-ime=true` for text input
- **Screen sharing:** Supported natively on Wayland (see section 4)

## 4. Screen Sharing and Multimedia on Wayland

### Screen Sharing with Audio
Discord now natively supports audio streaming with Wayland on Linux (v0.0.76+).

**How it works:**
- Uses PipeWire/PulseAudio for audio capture
- D-Bus integration for screen selection
- LibVesktop helper library on Linux for D-Bus events

**Requirements for full functionality:**
- PipeWire or PulseAudio installed (typically pre-installed)
- D-Bus session daemon running (Niri includes this)
- Proper permissions and composition support

### Alternatives for Screen Sharing

**Vesktop Advantages:**
- Specifically optimized for Linux Wayland
- Better compatibility with wlroots compositors like Niri
- Uses libvesktop helper library for improved D-Bus integration
- Preinstalled Vencord for additional features

**discord-screenaudio:**
- Specialized for audio capture during streaming
- Good for recording/streaming focused use

### PipeWire Configuration
For optimal audio during calls/screen shares, ensure PipeWire is configured properly:

```nix
# In nixosConfigurations for audio quality
services.pipewire.enable = true;
services.pipewire.pulse.enable = true;  # PulseAudio compatibility layer
```

## 5. Common Issues and Solutions

### Issue 1: Wayland Native Rendering Not Enabled
**Symptoms:** Discord using Xwayland (X11 mode) instead of native Wayland

**Solution A (System-wide):**
```bash
echo "NIXOS_OZONE_WL=1" >> ~/.bashrc
# Or set in systemd user environment
```

**Solution B (Per-session):**
Niri configuration can set this automatically in wayland-session systemd target.

**Solution C (Home-manager with programs):**
```nix
# Set environment variables in home session
home.sessionVariables = {
  NIXOS_OZONE_WL = "1";
};
```

### Issue 2: Screen Sharing Not Working
**Symptoms:** Can't select screens/can't share in Discord

**Causes & Solutions:**
1. **Missing PipeWire:** Install `pipewire` package
2. **D-Bus issues:** Ensure D-Bus session is running (automatic with Niri)
3. **Permissions:** Discord needs access to screencast portal
4. **Vesktop advantage:** Better integrated for Wayland screen sharing

**Quick fix:** Try Vesktop instead of official Discord:
```nix
home.packages = with pkgs; [
  vesktop  # Instead of discord
];
```

### Issue 3: No Audio During Screen Share
**Recent Fix (v0.0.76+):** Discord now supports audio with Wayland natively

**If still experiencing issues:**
1. Check Discord settings: User Settings → Voice & Video → Advanced
2. Ensure correct audio device selected
3. Try with PipeWire-specific settings:
   ```bash
   PIPEWIRE_PROPS="{\"link.max-buffers\":64}" discord
   ```

### Issue 4: Crackling/Audio Glitches
**Solutions:**
- Check PipeWire buffer settings
- Disable Discord hardware acceleration: Settings → Voice & Video → Debug
- Update Discord to latest version (nixpkgs unstable)
- Consider PipeWire configuration tuning

### Issue 5: Black Screen on Wayland (NVIDIA)
**Symptoms:** Blank window on NVIDIA GPUs with Wayland

**Solution:** Requires VA-API support
```nix
# Add to system packages for NVIDIA users
environment.systemPackages = with pkgs; [
  libva-nvidia-driver  # VA-API translation layer for NVIDIA
];
```

### Issue 6: Emoji Rendering Issues
**Symptoms:** Emojis appear as squares

**Solution:** Install emoji fonts
```nix
home.packages = with pkgs; [
  noto-fonts-emoji
  twemoji-color-font  # Optional for better rendering
];
```

### Issue 7: Update Prompts (Locked Out)
**Issue:** Discord refuses to launch saying "Must be your lucky day, there's a new update!"

**NixOS Solution:** Automatic via `disableUpdates = true` in discord/linux.nix

**Manual override if needed:**
```json
// ~/.config/discord/settings.json
{
  "SKIP_HOST_UPDATE": true
}
```

### Issue 8: Notification Sounds Not Working (PipeWire)
**Solution:** Configure PipeWire notification handling
```bash
# Or use Discord's built-in settings
# Settings → Notifications → uncheck "Desktop notification sounds" if problematic
```

### Issue 9: Microphone Volume Auto-Adjusting (Wireplumber)
**Solution:** Restrict Discord permissions
```nix
// ~/.config/wireplumber/wireplumber.conf.d/99-stop-microphone-auto-adjust.conf
access.rules = [
  {
    matches = [
      {
        application.process.binary = "discord"
      }
    ]
    actions = {
      update-props = {
        default_permissions = "rx"  # Read-only, no write
      }
    }
  }
]
```

## 6. Recommended NixOS Discord Configuration

### Basic Setup (Current - Minimal)
```nix
# modules/home-manager/hosts/nixos-desktop/default.nix
home.packages = with pkgs; [
  discord
];
```

### Enhanced Setup (Recommended for Niri)
```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vesktop  # Better Wayland support than official Discord
  ];

  # Enable Wayland rendering
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Optional: Configure Discord settings (no updates prompt)
  home.file.".config/discord/settings.json" = {
    text = builtins.toJSON {
      SKIP_HOST_UPDATE = true;
    };
  };
}
```

### Gaming/Power-User Setup
```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vesktop
    pipewire
    pipewire-pulse
    discord-screenaudio  # For dedicated streaming
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # Optional: Tweak audio buffer for better quality
    # PIPEWIRE_PROPS = "{\"link.max-buffers\":64}";
  };

  # Configure PipeWire for better audio
  services.pipewire.enable = true;
  
  home.file.".config/discord/settings.json" = {
    text = builtins.toJSON {
      SKIP_HOST_UPDATE = true;
      # Add more Discord settings as needed
    };
  };
}
```

## 7. Vesktop vs Official Discord Comparison

| Feature | Official Discord | Vesktop |
|---------|------------------|---------|
| Performance | Standard | Lighter, faster |
| Linux Support | Good | Excellent |
| Wayland Support | Good (with flags) | Excellent (native) |
| Screen Sharing | Works (v0.0.76+) | Works with audio |
| Audio Streaming | v0.0.76+ native | Native with libvesktop |
| Vencord Preinstalled | No | Yes |
| Customization | Limited | High (Vencord) |
| Terms of Service | Official | ⚠️ Unofficial (violates ToS) |
| Account Safety | Standard | Some risk with mods |
| File Size | ~280MB | ~240MB |
| Updates | Discord-controlled | Community-maintained |

**Note on Vesktop:** While Vesktop violates Discord's ToS technically, it's widely used with low reported account bans. Use at own discretion.

## 8. Installation Steps for Your Config

### Step 1: Keep Current Setup or Upgrade to Vesktop
**Option A (Keep Official - No changes needed):**
Current config already includes `discord` - it will work fine with Niri.

**Option B (Switch to Vesktop - Recommended):**
```nix
# In modules/home-manager/hosts/nixos-desktop/default.nix
home.packages = with pkgs; [
  code-cursor
  vesktop  # Changed from discord
  
  nautilus
  imv
  zathura
  swaylock-effects
  brightnessctl
  pavucontrol
  steam-run
];
```

### Step 2: Validate Configuration
```bash
nix flake check
# or
nb  # darwin-rebuild build equivalent
```

### Step 3: Optional - Add Wayland Environment Variable
```nix
# In modules/home-manager/hosts/nixos-desktop/default.nix
home.sessionVariables = {
  NIXOS_OZONE_WL = "1";
};
```

### Step 4: Apply Changes
```bash
# User applies via your nup command or:
sudo nixos-rebuild switch --flake .#nixos-desktop
```

## 9. Key Packages for Full Discord Experience on Niri

```nix
{
  # Core
  discord          # or vesktop
  
  # Audio
  pipewire
  pipewire-pulse
  alsa-lib         # Audio support
  
  # Emoji & Fonts  
  noto-fonts-emoji
  
  # Optional: Screen Share Audio
  discord-screenaudio
  
  # Optional: Terminal Client
  discordo
}
```

## 10. Troubleshooting Checklist

- [ ] Running on actual Wayland (check `echo $WAYLAND_DISPLAY`)
- [ ] `NIXOS_OZONE_WL=1` set in environment
- [ ] PipeWire/PulseAudio installed and running
- [ ] Discord not prompting for updates (v0.0.76+)
- [ ] Emoji fonts installed (noto-fonts-emoji)
- [ ] D-Bus session running (automatic with Niri)
- [ ] Proper audio device selected in Discord settings
- [ ] No notifications freezing client (disable if issues)
- [ ] GPU acceleration working (check chrome://gpu equivalent)

## References

- **nixpkgs Discord packages:** `/pkgs/applications/networking/instant-messengers/discord/`
- **Niri window manager:** https://github.com/YaLTeR/niri
- **Vesktop GitHub:** https://github.com/Vencord/Vesktop
- **ArchWiki Discord:** https://wiki.archlinux.org/title/Discord
- **NixOS Wayland support:** https://nixos.wiki/wiki/Wayland
