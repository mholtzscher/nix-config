# Shure MV7+ NixOS Quick Start

## Minimal System Configuration

Add to your NixOS `configuration.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  # === AUDIO SERVER SETUP ===
  
  # Disable PulseAudio (if enabled)
  hardware.pulseaudio.enable = lib.mkForce false;
  
  # Enable PipeWire
  services.pipewire = {
    enable = true;
    
    # ALSA emulation for legacy apps
    alsa = {
      enable = true;
      support32Bit = true;
    };
    
    # PulseAudio compatibility
    pulse.enable = true;
    
    # Optional: JACK support for professional audio
    # jack.enable = true;
  };
  
  # Enable real-time capabilities
  security.rtkit.enable = true;
  
  # === ESSENTIAL PACKAGES ===
  environment.systemPackages = with pkgs; [
    pipewire
    wireplumber           # Session manager
    alsa-utils            # arecord, aplay, amixer
    pavucontrol           # Volume control GUI
    qpwgraph              # PipeWire visualizer
  ];
  
  # === OPTIONAL: USER SETUP ===
  users.users.michael = {
    # Add to audio group for direct hardware access
    extraGroups = [ "audio" ];
  };
}
```

## Minimal Home-Manager Configuration

Add to your home-manager config:

```nix
{ config, pkgs, lib, ... }:

{
  # Enable EasyEffects for microphone effects (GUI)
  services.easyeffects = {
    enable = true;
  };
  
  # Optional: Add to packages for quick access
  home.packages = with pkgs; [
    easyeffects
    qpwgraph
  ];
}
```

## Step-by-Step Setup

### 1. Apply Configuration
```bash
sudo nixos-rebuild switch
```

### 2. Verify PipeWire is Running
```bash
# Check services
systemctl --user status pipewire
systemctl --user status wireplumber

# List audio devices
pw-dump | grep -i shure
```

### 3. Set MV7+ as Default Input
```bash
# Open pavucontrol GUI
pavucontrol

# Or via command line:
# List devices
pactl list sources

# Set default (replace with your device name)
pactl set-default-source alsa_input.usb-Shure_Inc_Shure_MV7-00.mono-fallback
```

### 4. Test Recording
```bash
# Record 3 seconds of audio
arecord -f cd -d 3 test.wav

# Play it back
aplay test.wav
```

### 5. (Optional) Enable Effects

**For GUI-based effects:**
1. Launch: `easyeffects`
2. Go to Input tab
3. Enable Noise Suppressor
4. Adjust threshold to 50%

**For command-line verification:**
```bash
# Check if easyeffects is running
systemctl --user status easyeffects
```

## Troubleshooting Steps

### Microphone Not Appearing

```bash
# Check USB connection
lsusb | grep -i shure

# View kernel logs
dmesg | grep -i usb | tail -10

# Check ALSA
arecord -l
```

### No Audio Input

```bash
# Check PipeWire nodes
pw-dump | grep node.name | grep input

# Check WirePlumber logs
journalctl --user -u wireplumber -n 20

# Restart services
systemctl --user restart pipewire wireplumber
```

### Permission Issues

```bash
# Check current user groups
groups

# Add to audio group (requires logout/login)
sudo usermod -aG audio $USER
```

## Verify Working Setup

```bash
# 1. Check PipeWire status
systemctl --user is-active pipewire

# 2. List input devices
pactl list sources short

# 3. Record test audio
arecord -f cd -d 2 /tmp/mic_test.wav

# 4. Verify file was created
file /tmp/mic_test.wav
```

## Next Steps

- **Advanced effects:** See `README.md` → Microphone Effects & Processing
- **Low latency:** See `README.md` → Performance Tuning
- **JACK support:** Enable `services.pipewire.jack.enable = true`
- **Virtual microphone:** See `README.md` → Advanced Configurations

## Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| MV7+ not detected | Check `lsusb`, verify USB driver loaded with `lsmod \| grep snd_usb` |
| No audio input | Select MV7+ in pavucontrol, raise volume |
| PipeWire crashes | Check `journalctl --user -u pipewire`, disable conflicting services |
| High latency | Enable low-latency mode in `services.pipewire.extraConfig` |
| Effects not working | Ensure `easyeffects` service is running: `systemctl --user status easyeffects` |

