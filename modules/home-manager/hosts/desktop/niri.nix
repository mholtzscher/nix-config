{ ... }:
{
  # Niri scrollable-tiling Wayland compositor config
  # This is a minimal experimental setup - feel free to customize!

  # Create Niri configuration file
  home.file.".config/niri/config.kdl" = {
    text = ''
      // Niri configuration

      // Monitor configuration for KVM setup
      output "DP-1" {
        mode "5120x1440@240"
        position x=0 y=0
        scale 1.0
      }

      // Layout settings
      layout {
        gaps 5
        struts { left = 0; right = 0; top = 0; bottom = 0; }
        default-column-width { proportion 0.5; }
        focus-ring {
          enable true
          width 2
          active-color "#6699cc"
          inactive-color "#1a1a1a"
        }
        border {
          enable true
          width 1
          active-color "#6699cc"
          inactive-color "#333333"
        }
        background-color "#0a0a0a"
      }

      // Input configuration
      input {
        keyboard {
          xkb { layout "us"; }
        }
        touchpad {
          tap true
          natural-scroll false
          accel-speed 0.2
          accel-profile "adaptive"
        }
        mouse {
          accel-speed 0.2
          accel-profile "adaptive"
        }
      }

      // Keybindings
      binds {
        // Applications
        Super+T { spawn "ghostty"; }
        Super+E { spawn "nautilus"; }
        Super+C { spawn "chromium"; }
        
        // Window navigation (Vim-style)
        Super+H { focus-column-left; }
        Super+L { focus-column-right; }
        Super+K { focus-window-up; }
        Super+J { focus-window-down; }

        // Window movement
        Super+Shift+H { move-column-left; }
        Super+Shift+L { move-column-right; }
        Super+Shift+K { move-window-up; }
        Super+Shift+J { move-window-down; }

        // Workspaces (1-10)
        Super+1 { workspace 1; }
        Super+2 { workspace 2; }
        Super+3 { workspace 3; }
        Super+4 { workspace 4; }
        Super+5 { workspace 5; }
        Super+6 { workspace 6; }
        Super+7 { workspace 7; }
        Super+8 { workspace 8; }
        Super+9 { workspace 9; }
        Super+0 { workspace 10; }

        // Move window to workspace
        Super+Shift+1 { move-window-to-workspace 1; }
        Super+Shift+2 { move-window-to-workspace 2; }
        Super+Shift+3 { move-window-to-workspace 3; }
        Super+Shift+4 { move-window-to-workspace 4; }
        Super+Shift+5 { move-window-to-workspace 5; }
        Super+Shift+6 { move-window-to-workspace 6; }
        Super+Shift+7 { move-window-to-workspace 7; }
        Super+Shift+8 { move-window-to-workspace 8; }
        Super+Shift+9 { move-window-to-workspace 9; }
        Super+Shift+0 { move-window-to-workspace 10; }

        // Window operations
        Super+Q { close-window; }
        Super+F { maximize-column; }
        Super+Shift+F { fullscreen-window; }

        // Column width
        Super+Minus { set-column-width 50%; }
        Super+Plus { set-column-width 100%; }

        // Exit
        Super+Alt+E { quit; }
      }

      // Animations
      animations {
        slowdown 3.0
      }

      prefer-no-csd true
    '';
  };
}
