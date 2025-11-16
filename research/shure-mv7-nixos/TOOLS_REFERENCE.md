# NixOS Audio Tools & Packages Reference

## Audio Servers & Routing

### PipeWire (Modern)
- **Package:** `pipewire`
- **Version:** Latest in nixpkgs
- **Type:** Audio server + routing daemon
- **Use Case:** Primary audio server for USB devices, Bluetooth, professional audio
- **Key Features:**
  - Native JACK emulation
  - Lower latency than PulseAudio
  - Better USB device handling
  - WirePlumber as default session manager

**Nix Configuration:**
```nix
services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
  jack.enable = true;
};
```

### WirePlumber
- **Package:** `wireplumber`
- **Version:** 0.4+ (default in 24.05+)
- **Type:** PipeWire session/policy manager
- **Use Case:** Manages PipeWire routing policies, device profiles, Bluetooth
- **Key Features:**
  - Replaces pipewire-media-session
  - Lua-based configuration
  - Per-device profiles
  - Bluetooth codec selection

**Nix Configuration:**
```nix
services.pipewire.wireplumber = {
  enable = true;
  
  extraConfig.example = {
    "setting.key" = "value";
  };
};
```

### PulseAudio (Legacy)
- **Package:** `pulseaudio` or `pulseaudioFull`
- **Type:** Legacy audio server
- **Use Case:** Compatibility with older apps, now superseded by PipeWire
- **Note:** Disable when using PipeWire

**Disable in Nix:**
```nix
hardware.pulseaudio.enable = false;
```

---

## Audio Control & Monitoring

### pavucontrol
- **Package:** `pavucontrol`
- **Version:** 6.1+
- **Type:** GTK GUI application
- **Use:** Volume control, per-application routing, device selection
- **Tabs:**
  - Playback (app volume control)
  - Recording (input device selection)
  - Output Devices (set default output)
  - Input Devices (set default input)
  - Configuration (device profiles)

**Works with:** PulseAudio and PipeWire

### pavucontrol-qt
- **Package:** `lxqt.pavucontrol-qt`
- **Version:** 2.3.0+
- **Type:** Qt-based alternative to pavucontrol
- **Use:** Lightweight PulseAudio control for Qt environments
- **Advantage:** Qt styling, lower resource usage

### pwvucontrol
- **Package:** `pwvucontrol`
- **Type:** Native PipeWire volume control
- **Use:** Modern alternative specifically for PipeWire
- **Advantage:** Built for PipeWire (not PulseAudio compatibility layer)

### qpwgraph
- **Package:** `qpwgraph`
- **Version:** 0.9.6+
- **Type:** Qt-based visual patchbay
- **Use:** View and manage PipeWire node connections graphically
- **Features:**
  - Visual node graph
  - Drag-and-drop connections
  - Connection persistence
  - Real-time signal flow visualization

**Nix Configuration:**
```nix
environment.systemPackages = with pkgs; [ qpwgraph ];
```

---

## Microphone Effects & Processing

### EasyEffects
- **Package:** `easyeffects`
- **Version:** 7.2.5+
- **Type:** Audio effects GUI (PipeWire-based)
- **Use:** Real-time microphone and speaker effects
- **Key Effects:**
  - Noise Suppression (RNNoise-based)
  - Compressor
  - Limiter
  - Equalizer
  - Gate
  - De-esser
  - Stereophonic Effect
  - Echo
  - Reverb

**Home-Manager Setup:**
```nix
services.easyeffects = {
  enable = true;
  preset = "voice-recording";  # Optional
  
  extraPresets = {
    voice-recording = {
      input = { ... };
      output = { ... };
    };
  };
};
```

**System Package:**
```nix
environment.systemPackages = with pkgs; [ easyeffects ];
```

### RNNoise & RNNoise Plugin
- **Packages:** `rnnoise`, `rnnoise-plugin`
- **Type:** Noise suppression library + LADSPA/LV2 plugin
- **Use:** Real-time background noise removal
- **Formats:** LADSPA, LV2
- **Quality:** Neural network-based, excellent for voice

**Direct PipeWire Integration:**
```nix
services.pipewire.extraConfig.pipewire."91-noise-suppression" = {
  "context.modules" = [
    {
      "name" = "libpipewire-module-filter-chain";
      "args" = {
        "node.description" = "Noise Cancelling";
        "filter.graph" = {
          "nodes" = [
            {
              "type" = "ladspa";
              "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
              "label" = "noise_suppressor_stereo";
              "control" = {
                "VAD Threshold (%)" = 50.0;
              };
            }
          ];
        };
      };
    }
  ];
};
```

### Carla
- **Package:** `carla`
- **Type:** Audio plugin host + patchbay
- **Use:** VST/LV2 plugin hosting, complex signal routing
- **Features:**
  - Plugin hosting (AU, LADSPA, DSSI, LV2, VST2, VST3)
  - Patchbay (visual signal routing)
  - JACK support (via PipeWire JACK API)
  - Rack view
  - Undo/redo

**Nix Setup:**
```nix
environment.systemPackages = with pkgs; [
  carla
  libjack2
];

services.pipewire.jack.enable = true;
```

### qjackctl
- **Package:** `qjackctl`
- **Type:** JACK control GUI
- **Use:** JACK daemon control and patchbay when using JACK
- **Note:** Works with PipeWire's JACK emulation

**Nix Setup:**
```nix
environment.systemPackages = with pkgs; [ qjackctl ];
services.pipewire.jack.enable = true;
```

---

## ALSA & Low-Level Tools

### alsa-utils
- **Package:** `alsa-utils`
- **Type:** ALSA command-line utilities
- **Key Tools:**
  - `arecord` - Record audio
  - `aplay` - Play audio
  - `amixer` - Mixer control
  - `alsamixer` - Interactive mixer
  - `alsactl` - Control persistence

**Essential for testing:**
```bash
arecord -f cd -d 3 test.wav  # Record 3 seconds
aplay test.wav               # Play recording
amixer sset Master 50%       # Set volume
```

### pamixer
- **Package:** `pamixer`
- **Type:** PulseAudio CLI mixer (PipeWire compatible)
- **Use:** Command-line volume control
- **Alternative to:** `pactl` for simpler interface

**Example:**
```bash
pamixer --get-volume       # Get volume
pamixer --set-volume 50    # Set volume
pamixer --increase 5       # Increase by 5%
pamixer --decrease 5       # Decrease by 5%
```

---

## JACK Support

### libjack2
- **Package:** `libjack2`
- **Type:** JACK library
- **Use:** Required for JACK audio applications
- **With PipeWire:** Provides JACK API emulation

### JACK Modules
- Enable via: `services.pipewire.jack.enable = true`
- PipeWire handles JACK client communication
- No need for separate JACK daemon

---

## Utility Packages

### rnnoise-plugin
- **Package:** `rnnoise-plugin`
- **Formats:** LADSPA, LV2
- **Use:** Noise suppression for any application supporting these formats

### speexdsp
- **Package:** `speexdsp`
- **Type:** Audio processing library
- **Use:** Acoustic echo cancellation, noise suppression
- **Used by:** EasyEffects, Mumble, other audio apps

### libsamplerate
- **Package:** `libsamplerate`
- **Type:** High-quality audio resampling
- **Use:** Sample rate conversion
- **Used by:** Many audio applications

---

## Package Installation Patterns

### System-Wide (all users)
```nix
environment.systemPackages = with pkgs; [
  # Core
  pipewire
  wireplumber
  alsa-utils
  
  # GUI tools
  pavucontrol
  qpwgraph
  easyeffects
  
  # Optional: Professional audio
  carla
  qjackctl
];
```

### User-Specific (home-manager)
```nix
home.packages = with pkgs; [
  easyeffects
  qpwgraph
];

# Or via services
services.easyeffects.enable = true;
```

### Services (auto-start)
```nix
# System-wide service
systemd.services.audio-service = { ... };

# User service (home-manager)
systemd.user.services.audio-service = { ... };
```

---

## Version Information

As of November 2025, NixOS unstable includes:

| Package | Version | Status |
|---------|---------|--------|
| pipewire | Latest | Stable |
| wireplumber | 0.4+ | Default |
| easyeffects | 7.2.5+ | Stable |
| qpwgraph | 0.9.6+ | Stable |
| rnnoise-plugin | 1.10+ | Stable |
| carla | Latest | Stable |
| alsa-utils | Latest | Stable |
| pavucontrol | 6.1+ | Stable |

---

## Configuration File Locations

| Component | Config Location | Format | Editor |
|-----------|-----------------|--------|--------|
| PipeWire | `/etc/pipewire/` | JSON/conf | Manual or `services.pipewire.extraConfig` |
| WirePlumber | `/etc/wireplumber/` | Lua/JSON | Manual or `services.pipewire.wireplumber.extraConfig` |
| EasyEffects | `$XDG_CONFIG_HOME/easyeffects/` | JSON | EasyEffects GUI or manual |
| ALSA | `/etc/asound.conf` | PCM config | `environment.etc` |
| JACK | `$HOME/.config/jack/` | XML | qjackctl GUI |

---

## Debugging Commands

```bash
# List all audio devices
pw-dump | grep -i node.name

# Check PipeWire status
systemctl --user status pipewire
systemctl --user status wireplumber

# View WirePlumber logs
journalctl --user -u wireplumber -n 50

# List USB audio devices
lsusb | grep -i audio

# Check kernel modules
lsmod | grep -i snd

# Record test audio
arecord -f cd test.wav

# List PulseAudio sources (works with PipeWire)
pactl list sources

# List available profiles
pactl list profiles

# Set default input
pactl set-default-source <source-name>
```

---

## Related Resources

- **GitHub:** nix-community/home-manager (easyeffects module)
- **GitHub:** wwmm/easyeffects (upstream)
- **GitHub:** rncbc/qpwgraph (upstream)
- **Docs:** https://pipewire.pages.freedesktop.org/
- **Docs:** https://pipewire.pages.freedesktop.org/wireplumber/

