# Omarchy-Nix Integration

This document describes how to use the omarchy-nix flake integration in this Nix configuration.

## Overview

Omarchy-nix is an opinionated NixOS configuration based on DHH's Omarchy project, providing a Hyprland-based desktop environment with theming and development tools.

## Available Configurations

### Standard NixOS (GNOME)
- **Configuration**: `nixos`
- **Desktop Environment**: GNOME
- **Display Manager**: GDM
- **Use Case**: Traditional desktop experience

### Omarchy NixOS (Hyprland)
- **Configuration**: `nixos-omarchy`
- **Desktop Environment**: Hyprland (Wayland)
- **Display Manager**: GDM with Wayland support
- **Use Case**: Tiling window manager, minimal desktop

## Switching Between Configurations

### To use standard GNOME desktop:
```bash
sudo nixos-rebuild switch --flake .#nixos
```

### To use Omarchy Hyprland desktop:
```bash
sudo nixos-rebuild switch --flake .#nixos-omarchy
```

### To test without switching:
```bash
sudo nixos-rebuild build --flake .#nixos-omarchy
```

## Omarchy Configuration

The omarchy configuration is set up with:

- **Theme**: Tokyo Night (default)
- **User**: Michael Holtzscher
- **Email**: michael@holtzscher.org

### Available Themes

- `tokyo-night` (default)
- `kanagawa`
- `everforest`
- `catppuccin`
- `nord`
- `gruvbox`
- `gruvbox-light`
- `generated_light` (from wallpaper)
- `generated_dark` (from wallpaper)

### Customizing Theme

Edit the `flake.nix` file in the `nixos-omarchy` configuration:

```nix
omarchy = {
  full_name = "Michael Holtzscher";
  email_address = "michael@holtzscher.org";
  theme = "kanagawa";  # Change theme here
  theme_overrides = {
    wallpaper_path = ./path/to/wallpaper.png;  # Optional custom wallpaper
  };
};
```

## What Omarchy Provides

### System Components
- Hyprland window manager
- Wayland compositor
- greetd display manager (minimal TUI login)
- NVIDIA GPU support
- Pipewire audio
- NetworkManager
- Bluetooth support

### Desktop Environment
- Hyprland with tiling window management
- Waybar status bar
- Themed terminal (Alacritty or Kitty)
- Application launcher (Rofi or Wofi)
- File manager (Yazi or similar)
- Development tools and editors

### Login Manager
Omarchy-nix uses **greetd** with **tuigreet** instead of GDM. This provides a minimal, fast TUI-based login experience. After boot, you'll see a terminal-based login screen where you can enter your credentials and Hyprland will start automatically.

### Theming
- Consistent color scheme across all applications
- Wallpaper integration
- Terminal color schemes
- Editor themes

## File Structure

```
hosts/nixos/
├── desktop.nix              # Standard GNOME configuration
└── desktop-omarchy.nix      # Omarchy-specific configuration

modules/home-manager/hosts/
├── desktop.nix              # Standard home-manager config
└── desktop-omarchy.nix      # Omarchy-specific home-manager config
```

## First Time Setup

1. **Backup current configuration**:
   ```bash
   sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
   ```

2. **Build omarchy configuration**:
   ```bash
   sudo nixos-rebuild build --flake .#nixos-omarchy
   ```

3. **Test in a separate session** (optional):
   ```bash
   sudo nixos-rebuild test --flake .#nixos-omarchy
   ```

4. **Switch to omarchy**:
   ```bash
   sudo nixos-rebuild switch --flake .#nixos-omarchy
   ```

5. **Reboot** to ensure all services start correctly:
   ```bash
   sudo reboot
   ```

6. **Login using greetd**:
   - After boot, you'll see a terminal-based login screen (not GDM)
   - Enter your username (michael) and password
   - Hyprland will start automatically

## Troubleshooting

### Hyprland doesn't start
- Ensure NVIDIA drivers are properly configured
- Check that greetd service is running: `systemctl status greetd`
- Verify hardware acceleration is working
- Check Hyprland logs: `journalctl -u greetd -b`

### No graphical login screen
- Omarchy-nix uses greetd (TUI) not GDM (GUI)
- You should see a terminal-based login prompt after boot
- Enter username and password, Hyprland will start automatically
- If greetd fails, check: `systemctl status greetd`

### Theme issues
- Rebuild configuration after changing themes
- Check wallpaper path is correct
- Ensure color scheme generation completed

### Performance issues
- Check NVIDIA power management settings
- Verify proper GPU driver installation
- Consider enabling NVIDIA's open drivers if supported

## Customization

### Adding Packages
Add system packages to `hosts/nixos/desktop-omarchy.nix`:
```nix
environment.systemPackages = with pkgs; [
  vim
  git
  your-package-here
];
```

### Home Manager Customization
Add user-specific configurations to `modules/home-manager/hosts/desktop-omarchy.nix`:
```nix
{
  programs.your-program.enable = true;
  home.file.".config/your-config".source = ./your-config-file;
}
```

### Hyprland Configuration
Omarchy provides base Hyprland configuration. For customizations:
1. Override in home-manager configuration
2. Use `theme_overrides` for visual changes
3. Add custom keybindings and rules as needed

## Resources

- [Omarchy-Nix GitHub](https://github.com/henrysipp/omarchy-nix)
- [Hyprland Documentation](https://wiki.hyprland.org/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)