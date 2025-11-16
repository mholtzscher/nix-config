# Shure MV7+ Microphone Configuration on NixOS

Comprehensive guide for setting up the Shure MV7+ USB microphone on NixOS with professional audio processing.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Audio Server Setup](#audio-server-setup)
3. [Microphone Effects & Processing](#microphone-effects--processing)
4. [Configuration Patterns](#configuration-patterns)
5. [Graphical Tools](#graphical-tools)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Configurations](#advanced-configurations)

---

## Quick Start

**Minimal Working Configuration:**

```nix
# System-level configuration
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  wireplumber.enable = true;  # Default session/policy manager
};

security.rtkit.enable = true;  # Required for real-time audio

# User-level packages
environment.systemPackages = with pkgs; [
  pipewire
  alsa-utils
  pavucontrol       # PulseAudio volume control (works with PipeWire)
  qpwgraph          # PipeWire graph visualizer
];
```

---

## Audio Server Setup

### PipeWire (Recommended)

**Why PipeWire for USB microphones?**
- Modern audio server replacing PulseAudio + JACK
- Better USB device handling and Bluetooth support
- Lower latency with minimal CPU overhead
- Native JACK emulation for professional audio apps
- WirePlumber is default session manager (replaces media-session)

**System Configuration:**

```nix
services.pipewire = {
  enable = true;
  
  # Enable ALSA emulation layer
  alsa = {
    enable = true;
    support32Bit = true;
  };
  
  # Enable PulseAudio compatibility
  pulse.enable = true;
  
  # Optional: Enable JACK support for professional audio
  jack.enable = true;
  
  # WirePlumber is enabled by default in 24.05+
  wireplumber.enable = true;
};

# Enable real-time kernel capabilities
security.rtkit.enable = true;

# Optional: User in audio group for system-wide access
users.users.michael.extraGroups = [ "audio" ];
```

**PipeWire Configuration for USB Microphone:**

```nix
services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
  # USB-specific settings if needed
  "monitor.alsa.properties" = {
    "alsa.jack-device" = false;
  };
};
```

### Bluetooth Audio (Optional)

If using wireless version or for future expansion:

```nix
services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
  "monitor.bluez.properties" = {
    "bluez5.enable-sbc-xq" = true;      # Better audio quality
    "bluez5.enable-msbc" = true;        # Better codec for calls
    "bluez5.enable-hw-volume" = true;   # Hardware volume control
    "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
  };
};

hardware.bluetooth.enable = true;
```

---

## Microphone Effects & Processing

### EasyEffects (Recommended for GUI)

**Best for:** Applying effects like noise suppression, compressors, equalizers with visual feedback.

**Installation & Configuration:**

```nix
# home-manager configuration
services.easyeffects = {
  enable = true;
  preset = "voice-recording";  # Optional: load a preset at startup
};

# Or add to environment.systemPackages for CLI access
environment.systemPackages = with pkgs; [
  easyeffects
  easyeffects-presets  # If available
];
```

**EasyEffects Features:**
- Noise suppression (RNNoise-based)
- Compressor
- Equalizer
- Spectral analyzer
- Gate
- De-esser
- Auto-leveler

**Example Preset Configuration:**

```nix
services.easyeffects = {
  enable = true;
  
  extraPresets = {
    voice-recording = {
      input = {
        blocklist = [];
        
        # Configure specific plugins
        plugins.noise_suppressor = {
          # Settings will be saved to EasyEffects config
        };
      };
      
      output = {
        blocklist = [];
      };
    };
  };
};
```

### PipeWire Filter Chain (Declarative, no GUI)

**Best for:** Declarative, reproducible configuration without GUI.

**RNNoise Noise Suppression:**

```nix
services.pipewire.extraConfig.pipewire."91-noise-suppression" = {
  "context.modules" = [
    {
      "name" = "libpipewire-module-filter-chain";
      "args" = {
        "node.description" = "Noise Cancelling Microphone";
        "media.name" = "Noise Cancelling Microphone";
        "filter.graph" = {
          "nodes" = [
            {
              "type" = "ladspa";
              "name" = "rnnoise";
              "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
              "label" = "noise_suppressor_stereo";
              "control" = {
                "VAD Threshold (%)" = 50.0;  # Adjust 0-100
              };
            }
          ];
          "links" = [
            { "output" = "rnnoise:output_left"; "input" = "system:playback_FL"; }
            { "output" = "rnnoise:output_right"; "input" = "system:playback_FR"; }
          ];
        };
        "audio.position" = [ "FL" "FR" ];
        "capture.props" = {
          "node.name" = "effect_input.rnnoise";
          "node.passive" = true;
        };
      };
    }
  ];
};

# Include rnnoise-plugin in system packages
environment.systemPackages = with pkgs; [
  rnnoise-plugin
];
```

### Carla (Professional Audio Routing)

**Best for:** Complex signal routing and VST/LV2 plugin chains.

```nix
# System packages
environment.systemPackages = with pkgs; [
  carla
  libjack2
];

# Enable JACK support
services.pipewire.jack.enable = true;
```

**Launch:** `carla` → Settings → Use PipeWire's JACK API

### qpwgraph (Visual PipeWire Router)

**Best for:** Visual node connections and signal flow debugging.

```nix
environment.systemPackages = with pkgs; [
  qpwgraph
];

# Optional: Auto-start config save
home.file.".config/qpwgraph/audio.qpwgraph".text = "# Will be generated by qpwgraph";
```

---

## Configuration Patterns

### USB Microphone Detection

**Find your MV7+ USB device:**

```bash
# List all audio devices
pw-dump | grep -i usb

# Or use alsa-utils
arecord -l

# Or older style
lsusb | grep -i shure
```

**Expected output pattern:**
- `alsa_input.usb-*` for USB inputs
- Device name typically includes "Shure" and model identifier

### Microphone-Specific Tuning

**Low-level device properties (if needed):**

```nix
services.pipewire.wireplumber.configPackages = [
  (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-usb-mic.lua" ''
    alsa_monitor.rules = {
      {
        matches = {
          { "node.name", "matches", "alsa_input.usb-Shure*" }
        };
        apply_properties = {
          -- Capture settings
          ["audio.format"] = "S32LE",           -- 32-bit samples
          ["audio.rate"] = "48000",            -- Sample rate
          ["api.alsa.period-size"] = 2048,     -- Buffer size
          ["api.alsa.disable-batch"] = true,   -- USB specific
          ["node.latency"] = "2048/48000",
        };
      };
    }
  '')
];
```

### Virtual Microphone with Effects

**Create a virtual mic with processing applied:**

```nix
services.pipewire.extraConfig.pipewire."91-virtual-mic" = {
  "context.objects" = [
    {
      factory = "adapter";
      args = {
        "factory.name" = "support.null-audio-sink";
        "node.name" = "Processed-Microphone";
        "node.description" = "MV7+ with Effects";
        "media.class" = "Audio/Source/Virtual";
        "audio.position" = "MONO";
      };
    }
  ];
};
```

---

## Graphical Tools

### Audio Control Tools

| Tool | Purpose | Package | Best For |
|------|---------|---------|----------|
| **pavucontrol** | Volume/routing control | `pavucontrol` | Per-app routing, device selection |
| **qpwgraph** | Visual connection manager | `qpwgraph` | Seeing signal flow |
| **easyeffects** | Effects GUI | `easyeffects` | Real-time effects with presets |
| **qjackctl** | JACK control | `qjackctl` | JACK clients (if enabled) |
| **pwvucontrol** | Modern PW volume | `pwvucontrol` | PipeWire-native volume control |
| **pavucontrol-qt** | Qt version | `lxqt.pavucontrol-qt` | Lightweight alternative |

**Recommended System Packages:**

```nix
environment.systemPackages = with pkgs; [
  # PipeWire core
  pipewire
  wireplumber
  
  # Audio utilities
  alsa-utils           # arecord, aplay, amixer CLI tools
  pamixer              # pactl alternative
  
  # GUI tools
  pavucontrol          # PulseAudio control (works with PW)
  qpwgraph             # PipeWire graph
  easyeffects          # Effects processor
  
  # Optional: professional audio
  qjackctl             # If JACK enabled
  carla                # VST/LV2 host
];
```

---

## Troubleshooting

### Microphone Not Detected

**Check 1: Device enumeration**
```bash
# See all input devices
pw-dump | grep -E '"type": "PipeWire:Interface:Node"' -A 10 | grep -E 'node.name|object.serial'

# Or with alsa
arecord -l
```

**Check 2: USB driver loaded**
```bash
# Verify USB drivers
lsmod | grep -i usb
lsmod | grep -i snd_usb

# Check kernel logs
dmesg | grep -i usb | tail -20
```

**Check 3: Permissions**
```bash
# Verify audio group
groups username

# Add user to audio group (requires restart)
# In configuration.nix: users.users.username.extraGroups = [ "audio" ];
```

### No Sound Input

**Try:**
1. Open pavucontrol → Input Devices tab
2. Select MV7+ as default input device
3. Raise input volume
4. Test recording: `arecord -f cd test.wav`

### PipeWire Won't Start

**Check service status:**
```bash
systemctl --user status pipewire
systemctl --user status wireplumber

# View logs
journalctl --user -u pipewire -n 50
journalctl --user -u wireplumber -n 50
```

**Common fixes:**
- Disable PulseAudio: `hardware.pulseaudio.enable = false;`
- Rebuild and restart: `nix flake update && nixos-rebuild switch`

### Latency Issues

**For low-latency recording:**

```nix
# Low-latency PipeWire config
services.pipewire.extraConfig.pipewire."92-low-latency" = {
  "context.properties" = {
    "default.clock.rate" = 48000;
    "default.clock.quantum" = 32;
    "default.clock.min-quantum" = 32;
    "default.clock.max-quantum" = 32;
  };
};
```

---

## Advanced Configurations

### Multi-Format Support

```nix
services.pipewire.wireplumber.configPackages = [
  (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-formats.lua" ''
    alsa_monitor.rules = {
      {
        matches = {
          { "node.name", "matches", "alsa_input.usb-Shure*" }
        };
        apply_properties = {
          ["audio.format"] = "F32LE",      -- Float 32-bit
          ["audio.channels"] = 1,           -- Mono (MV7+ is mono)
          ["audio.position"] = "MONO",
        };
      };
    }
  '')
];
```

### Automatic Input Selection

```nix
# WirePlumber default device policy
services.pipewire.wireplumber.extraConfig.defaultAudioRouting = {
  "monitor.alsa.properties" = {
    "alsa.monitor-enabled" = true;
  };
};
```

### Recording Quality Preset

```nix
environment.etc."asound.conf".text = ''
  defaults.pcm.device 0
  defaults.ctl.device 0
  
  pcm.!default {
    type asym
    playback.pcm "output"
    capture.pcm "input"
  }
  
  pcm.input {
    type hw
    card 0
    device 0
  }
  
  pcm.output {
    type hw
    card 0
    device 0
  }
'';
```

---

## Performance Tuning

### Real-Time Audio Priority

```nix
security.pam.loginLimits = [
  { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
  { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
];
```

### Kernel Parameters (Optional)

```nix
boot.kernel.sysctl = {
  "vm.swappiness" = 10;              # Reduce swapping
  "fs.inotify.max_user_watches" = 524288;  # For audio apps
};
```

---

## Key Packages

| Package | Purpose | Version | Notes |
|---------|---------|---------|-------|
| `pipewire` | Audio server | Latest | Core audio routing |
| `wireplumber` | Session manager | 0.4+ | Default for PW |
| `easyeffects` | Effects GUI | 7.2+ | Uses PipeWire |
| `qpwgraph` | Visual patchbay | 0.9+ | PipeWire graphs |
| `alsa-utils` | ALSA CLI tools | Latest | arecord, aplay, amixer |
| `rnnoise-plugin` | Noise suppression | 1.10+ | LADSPA/LV2 plugin |
| `carla` | Audio plugin host | Latest | VST/LV2 support |
| `pavucontrol` | Volume control | 6.1+ | PulseAudio/PW compatible |

---

## References

- **NixOS PipeWire Wiki:** https://nixos.wiki/wiki/PipeWire
- **NixOS JACK Wiki:** https://nixos.wiki/wiki/JACK
- **PipeWire Documentation:** https://pipewire.pages.freedesktop.org/
- **WirePlumber Docs:** https://pipewire.pages.freedesktop.org/wireplumber/
- **EasyEffects GitHub:** https://github.com/wwmm/easyeffects
- **RNNoise Project:** https://gitlab.xiph.org/xiph/rnnoise

---

## Related Research Topics

- `discord-niri/` - Audio setup for Discord on Niri
- `steam-niri/` - Audio configuration for gaming
- `wallpaper-rotation/` - System configuration patterns

