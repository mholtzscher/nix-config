# Quick Start: wpaperd on NixOS/Niri

**TL;DR:** Use **wpaperd** for 500+ image rotation. Setup takes 5 minutes.

---

## 1. Create Wallpaper Directory

```bash
mkdir -p ~/.config/wallpapers
cp ~/Pictures/wallpapers/*.{jpg,png} ~/.config/wallpapers/

# Verify
ls ~/.config/wallpapers/ | wc -l  # Should show 500+
```

---

## 2. Find Your Display Name

```bash
wlr-randr
# Look for output name like: DP-1, HDMI-A-1, eDP-1, etc.
```

---

## 3. Update NixOS Config

Replace `modules/nixos/hosts/nixos-desktop/wallpaper.nix`:

```nix
{ pkgs, ... }:
{
  home-manager.sharedModules = [
    {
      home.packages = with pkgs; [ wpaperd ];
      
      home.file.".config/wpaperd/config.toml".text = ''
        [default]
        duration = "1m"
        sorting = "random"
        mode = "fill"
        transition-time = 300
        
        ["DP-1"]
        path = "''${HOME}/.config/wallpapers"
      '';
      
      systemd.user.services.wpaperd = {
        Unit = {
          Description = "Modern wallpaper daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session-pre.target" ];
        };
        
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.wpaperd}/bin/wpaperd -d";
          Restart = "on-failure";
        };
        
        Install.WantedBy = [ "graphical-session.target" ];
      };
    }
  ];
}
```

**Note:** Replace `"DP-1"` with your actual display name from step 2.

---

## 4. Deploy

```bash
nb   # Validate configuration
nup  # Apply changes
```

---

## 5. Verify

```bash
# Check service
systemctl --user status wpaperd

# Check status
wpaperctl status

# Manual control (optional)
wpaperctl next     # Jump to next
wpaperctl pause    # Pause rotation
wpaperctl resume   # Resume
```

---

## What You Get

✅ Wallpaper changes every 60 seconds  
✅ Smooth fade transitions (300ms)  
✅ 5-10 MB memory usage  
✅ <0.5% idle CPU, 1-2% during rotation  
✅ Perfect for 500+ images  

---

## Troubleshooting

**Wallpaper not changing?**
```bash
# 1. Check display name
wpaperctl status

# 2. Verify images exist
ls ~/.config/wallpapers/*.{jpg,png} | head

# 3. Check logs
journalctl --user -u wpaperd -n 20
```

**High CPU?**
- Reduce `transition-time` to 200
- Reduce `queue-size` to 5

**Wallpaper missing after display reconnect?**
```bash
systemctl --user restart wpaperd
```

---

## Advanced Config Options

See `comprehensive-analysis.md` for:
- 40+ transition types
- Multi-display setups
- Performance tuning
- On-change scripts
- Sequential vs random rotation

---

## Stuck?

1. Read `README.md` (5 min overview)
2. Check `comprehensive-analysis.md` (detailed reference)
3. Follow `implementation-guide.md` (step-by-step)

