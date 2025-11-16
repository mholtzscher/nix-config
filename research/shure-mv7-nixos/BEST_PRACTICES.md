# NixOS Shure MV7+ Best Practices

## 1. Audio Server Configuration

### ✅ DO: Use PipeWire for New Setups

```nix
# Modern, recommended approach
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
};

hardware.pulseaudio.enable = false;  # Explicitly disable
security.rtkit.enable = true;        # Real-time capabilities
```

### ❌ DON'T: Use Both PipeWire and PulseAudio

```nix
# WRONG: Conflicting audio servers
services.pipewire.enable = true;
hardware.pulseaudio.enable = true;  # Will cause issues
```

### ✅ DO: Ensure WirePlumber is Enabled

```nix
# WirePlumber is default in 24.05+
# Explicitly verify:
services.pipewire.wireplumber.enable = true;
```

---

## 2. Microphone Detection & Setup

### ✅ DO: Test Device Detection Before Configuration

```bash
# Step 1: Verify physical connection
lsusb | grep -i shure

# Step 2: Check ALSA recognition
arecord -l

# Step 3: View PipeWire nodes
pw-dump | grep -i usb

# Step 4: Set as default before scripting
pactl set-default-source <device-name>
```

### ✅ DO: Use Declarative Device Matching

```nix
# Instead of hardcoding device names
services.pipewire.wireplumber.configPackages = [
  (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-mic.lua" ''
    alsa_monitor.rules = {
      {
        matches = {
          { "node.name", "matches", "alsa_input.usb-Shure*" }
        };
        apply_properties = {
          ["node.description"] = "Shure MV7+ Microphone";
          ["audio.format"] = "S32LE";
          ["audio.rate"] = "48000";
        };
      };
    }
  '')
];
```

### ❌ DON'T: Hardcode Specific USB Port Addresses

```nix
# WRONG: Will break if you use different USB port
alsa_input.usb-Shure_Inc_Shure_MV7-00-Port_1

# RIGHT: Use pattern matching
alsa_input.usb-Shure*
```

---

## 3. Effects & Processing

### ✅ DO: Start with EasyEffects GUI for Testing

```bash
# Install and test first
nix run nixpkgs#easyeffects

# Then enable in config once settings are saved
services.easyeffects.enable = true;
```

### ✅ DO: Use Presets for Reproducibility

```nix
# Save settings to preset for portability
services.easyeffects = {
  enable = true;
  preset = "voice-recording";
  
  extraPresets = {
    voice-recording = {
      input = {
        blocklist = [];  # Process all inputs through effects
      };
      output = {
        blocklist = [];
      };
    };
  };
};
```

### ✅ DO: Use RNNoise for Background Noise

```nix
# Neural network-based noise suppression
services.pipewire.extraConfig.pipewire."91-rnnoise" = {
  "context.modules" = [
    {
      "name" = "libpipewire-module-filter-chain";
      "args" = {
        "node.description" = "Noise Cancelling Microphone";
        "filter.graph" = {
          "nodes" = [
            {
              "type" = "ladspa";
              "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
              "label" = "noise_suppressor_stereo";
              "control" = { "VAD Threshold (%)" = 50.0; };
            }
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
```

### ❌ DON'T: Chain Too Many Effects

```nix
# WRONG: Performance degradation
# Multiple compressors + equalizers + gate + reverb all on MIC input

# RIGHT: Minimal essential effects
# 1. Gate (remove silence)
# 2. Noise Suppressor (background noise)
# 3. Compressor (level control) - optional
```

---

## 4. Performance Optimization

### ✅ DO: Enable Low-Latency for Recording

```nix
# For real-time recording (streaming, calls)
services.pipewire.extraConfig.pipewire."92-low-latency" = {
  "context.properties" = {
    "default.clock.rate" = 48000;
    "default.clock.quantum" = 32;      # Lower = less latency
    "default.clock.min-quantum" = 32;
    "default.clock.max-quantum" = 32;
  };
};
```

### ✅ DO: Enable Real-Time Priority

```nix
# Required for audio work
security.rtkit.enable = true;

# Optional: Grant priority to audio group
security.pam.loginLimits = [
  { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
  { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
];
```

### ✅ DO: Add User to Audio Group

```nix
users.users.michael = {
  extraGroups = [ "audio" ];
};
```

### ❌ DON'T: Use Maximum Performance at All Times

```nix
# WRONG: Wastes CPU, generates heat
"default.clock.quantum" = 2;  # Too low for USB

# RIGHT: Balance latency and performance
"default.clock.quantum" = 32;  # ~0.67ms at 48kHz
```

---

## 5. Testing & Troubleshooting

### ✅ DO: Test in Stages

```bash
# Stage 1: Device detection
lsusb | grep -i shure
arecord -l

# Stage 2: Basic recording
arecord -f cd -d 3 test.wav

# Stage 3: PipeWire integration
pactl list sources | grep -i shure

# Stage 4: Effects
systemctl --user status easyeffects
```

### ✅ DO: Check Logs When Issues Occur

```bash
# PipeWire logs
journalctl --user -u pipewire -n 50

# WirePlumber logs
journalctl --user -u wireplumber -n 50

# Full system audio
journalctl -f | grep -i audio
```

### ✅ DO: Document Your Configuration

```nix
# Add comments explaining choices
services.pipewire = {
  enable = true;
  
  # USB microphone support
  alsa.enable = true;
  alsa.support32Bit = true;
  
  # Compatibility with older apps
  pulse.enable = true;
  
  # Professional audio support (if needed)
  # jack.enable = true;
};
```

---

## 6. Configuration Organization

### ✅ DO: Use Modular Configuration Structure

```
modules/
├── nixos/
│   └── audio.nix              # System audio setup
└── home-manager/
    └── programs/
        └── audio.nix          # User audio programs
```

### ✅ DO: Separate System & User Config

```nix
# /etc/nixos/configuration.nix - System level
services.pipewire.enable = true;
security.rtkit.enable = true;

# $HOME/.config/home-manager/home.nix - User level
services.easyeffects.enable = true;
```

### ✅ DO: Version Your Audio Configuration

```nix
# Comment with version info
# Updated: 2025-11-15
# PipeWire: 1.0+
# WirePlumber: 0.4+
# EasyEffects: 7.2+
```

---

## 7. Microphone-Specific Tips

### ✅ DO: Use Monitor Latency Settings

```nix
# USB devices often need specific settings
services.pipewire.wireplumber.configPackages = [
  (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-usb.lua" ''
    alsa_monitor.rules = {
      {
        matches = {
          { "node.name", "matches", "alsa_input.usb-*" }
        };
        apply_properties = {
          ["api.alsa.disable-batch"] = true;    -- USB typically needs this
          ["api.alsa.period-size"] = 2048;      -- 48ms at 48kHz
          ["node.latency"] = "2048/48000";
        };
      };
    }
  '')
];
```

### ✅ DO: Adjust Noise Suppression to Your Environment

```nix
# Quieter environment: higher threshold (less aggressive)
"VAD Threshold (%)" = 70.0;

# Noisy environment: lower threshold (more aggressive)
"VAD Threshold (%)" = 30.0;

# Balanced (default)
"VAD Threshold (%)" = 50.0;
```

### ✅ DO: Test MV7+ Specific Features

```bash
# Some MV7+ models have hardware mixing
# Test with pavucontrol to see device profiles

# Open pavucontrol
pavucontrol

# Go to Configuration tab
# Look for available profiles (may vary by model)
```

---

## 8. Integration with Other Systems

### ✅ DO: Ensure Discord/Chat Apps Work

```nix
# Discord uses PulseAudio protocol
services.pipewire.pulse.enable = true;

# Test with simple app
environment.systemPackages = with pkgs; [ audacity ];  # Has input devices selection
```

### ✅ DO: Support Browser WebRTC

```bash
# Most browsers use PulseAudio API (even on PipeWire)
# Should work automatically once configured
```

### ✅ DO: Handle JACK Applications (if needed)

```nix
# Enable JACK emulation
services.pipewire.jack.enable = true;

# Then use:
environment.systemPackages = with pkgs; [
  carla       # VST host
  qjackctl    # JACK control
];
```

---

## 9. Backup & Recovery

### ✅ DO: Backup Working Configurations

```bash
# Save to git
git add -A
git commit -m "Add working Shure MV7+ audio configuration"

# Backup EasyEffects presets
cp -r ~/.config/easyeffects ~/backups/
```

### ✅ DO: Keep Simple Fallback Config

```nix
# Basic config that always works
services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
};

# Comment out advanced features if needed:
# services.pipewire.wireplumber.configPackages = [ ... ];
```

---

## 10. Common Issues & Prevention

### Problem: Device Not Recognized
**Prevention:**
- Verify USB connection
- Use pattern matching instead of hardcoding
- Check kernel version supports `snd_usb` module

### Problem: Audio Cutting Out
**Prevention:**
- Adjust buffer size (`quantum` setting)
- Lower CPU usage (reduce effects)
- Check CPU frequency scaling

### Problem: Effects Causing Noise
**Prevention:**
- Start with one effect at a time
- Adjust threshold values gradually
- Monitor CPU usage

### Problem: PipeWire Won't Start
**Prevention:**
- Ensure PulseAudio is disabled
- Check log files immediately
- Keep configuration minimal initially

---

## Quick Reference Checklist

- [ ] Disable PulseAudio: `hardware.pulseaudio.enable = false;`
- [ ] Enable PipeWire with ALSA: `services.pipewire.alsa.enable = true;`
- [ ] Enable PulseAudio compat: `services.pipewire.pulse.enable = true;`
- [ ] Enable rtkit: `security.rtkit.enable = true;`
- [ ] Add user to audio group: `extraGroups = [ "audio" ];`
- [ ] Install essential packages: `pipewire, alsa-utils, pavucontrol, qpwgraph`
- [ ] Test with `arecord -f cd -d 3 test.wav`
- [ ] Enable easyeffects: `services.easyeffects.enable = true;`
- [ ] Configure low-latency if needed
- [ ] Document your settings

