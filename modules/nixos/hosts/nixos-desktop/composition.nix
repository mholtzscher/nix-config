{
  pkgs,
  user,
  ...
}:
let
  refreshDisplays = pkgs.writeShellScriptBin "refresh-displays" ''
    set -eu

    NIRI_MSG="${pkgs.niri}/bin/niri msg"

    # Step 1: Try Niri DPMS power cycle — this forces DisplayPort link re-negotiation
    # which is what KVMs need after switching back.
    if $NIRI_MSG action power-off-monitors 2>/dev/null; then
      sleep 1
      $NIRI_MSG action power-on-monitors
      echo "KVM recovery: DPMS power cycle completed via Niri"
      exit 0
    fi

    echo "Niri DPMS not available, trying wlr-randr fallback..." >&2

    # Step 2: Try wlr-randr as a fallback
    if command -v wlr-randr >/dev/null 2>&1; then
      for output in DP-1 HDMI-A-1; do
        if wlr-randr --output "$output" --off 2>/dev/null; then
          sleep 1
          wlr-randr --output "$output" --on 2>/dev/null || true
          echo "KVM recovery: cycled $output via wlr-randr"
        fi
      done
      exit 0
    fi

    echo "No display management tool available (niri/wlr-randr)" >&2
    exit 1
  '';
in
{
  # Wayland composition stack: Niri window manager + DankMaterialShell
  # This module manages the setup for the desktop environment
  # Note: Niri module is loaded from inputs in lib/default.nix when graphical=true

  environment.systemPackages = [
    refreshDisplays
  ];



  # Niri settings + DMS keybinds via home-manager
  home-manager.sharedModules = [
    {
      # Niri window manager settings
      programs.niri.settings = {
        # Monitor configuration
        outputs."DP-1" = {
          mode = {
            width = 5120;
            height = 1440;
            refresh = 120.0;
          };
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.0;
        };

        # Layout settings
        layout = {
          gaps = 16;
          center-focused-column = "always";

          # DMS integrates wallpapers into the overview; keep layout background transparent.
          background-color = "transparent";

          default-column-width = {
            proportion = 0.5;
          };

          preset-column-widths = [
            { proportion = 0.25; }
            { proportion = 0.5; }
            { proportion = 0.75; }
          ];

          focus-ring = {
            width = 0;
          };

          border = {
            width = 0;
          };
        };

        # Input configuration
        input = {
          keyboard.xkb.layout = "us";

          touchpad = {
            tap = true;
            accel-speed = 0.2;
            accel-profile = "adaptive";
          };

          mouse = {
            accel-speed = 0.2;
            accel-profile = "adaptive";
          };
        };

        # Keybindings
        binds = {
          # Media keys (PipeWire)
          "XF86AudioRaiseVolume".action.spawn = [
            "wpctl"
            "set-volume"
            "-l"
            "1.0"
            "@DEFAULT_AUDIO_SINK@"
            "5%+"
          ];
          "XF86AudioLowerVolume".action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "5%-"
          ];
          "XF86AudioMute".action.spawn = [
            "wpctl"
            "set-mute"
            "@DEFAULT_AUDIO_SINK@"
            "toggle"
          ];

          # DankMaterialShell
          "Mod+Space".action.spawn = [
            "dms"
            "ipc"
            "call"
            "spotlight"
            "toggle"
          ];
          "Mod+V".action.spawn = [
            "dms"
            "ipc"
            "call"
            "clipboard"
            "toggle"
          ];
          "Mod+M".action.spawn = [
            "dms"
            "ipc"
            "call"
            "processlist"
            "focusOrToggle"
          ];
          "Mod+Comma".action.spawn = [
            "dms"
            "ipc"
            "call"
            "settings"
            "focusOrToggle"
          ];
          "Mod+N".action.spawn = [
            "dms"
            "ipc"
            "call"
            "notifications"
            "toggle"
          ];
          "Mod+Y".action.spawn = [
            "dms"
            "ipc"
            "call"
            "dankdash"
            "wallpaper"
          ];
          "Mod+Alt+L".action.spawn = [
            "dms"
            "ipc"
            "call"
            "lock"
            "lock"
          ];

          # Restart DMS shell (workaround for IPC issues after KVM/sleep)
          "Mod+Shift+D".action.spawn = [
            "systemctl"
            "--user"
            "restart"
            "dms.service"
          ];

          # Force DisplayPort link re-negotiation after a missed KVM hotplug event.
          # Press blind if the KVM returns with no visible output.
          # Powers monitors off/on via DPMS to trigger GPU link re-training.
          "Mod+Shift+O".action.spawn = [
            "${refreshDisplays}/bin/refresh-displays"
          ];

          # Dictation - speech-to-text using whisper.cpp
          "Mod+Slash".action.spawn = [
            "bash"
            "-c"
            "exec $HOME/bin/dictate"
          ];

          # Applications
          "Mod+T".action.spawn = "ghostty";
          "Mod+E".action.spawn = "nautilus";
          "Mod+B".action.spawn = "helium";

          # Hotkey overlay
          "Mod+Shift+Slash".action.show-hotkey-overlay = { };

          # Window navigation (Vim-style)
          "Mod+H".action.focus-column-left = { };
          "Mod+L".action.focus-column-right = { };
          "Mod+K".action.focus-window-up = { };
          "Mod+J".action.focus-window-down = { };

          # Window movement
          "Mod+Shift+H".action.move-column-left = { };
          "Mod+Shift+L".action.move-column-right = { };
          "Mod+Shift+K".action.move-window-up = { };
          "Mod+Shift+J".action.move-window-down = { };

          # Workspaces
          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;
          "Mod+0".action.focus-workspace = 10;

          # Move to workspace
          "Mod+Ctrl+1".action.move-column-to-workspace = 1;
          "Mod+Ctrl+2".action.move-column-to-workspace = 2;
          "Mod+Ctrl+3".action.move-column-to-workspace = 3;
          "Mod+Ctrl+4".action.move-column-to-workspace = 4;
          "Mod+Ctrl+5".action.move-column-to-workspace = 5;
          "Mod+Ctrl+6".action.move-column-to-workspace = 6;
          "Mod+Ctrl+7".action.move-column-to-workspace = 7;
          "Mod+Ctrl+8".action.move-column-to-workspace = 8;
          "Mod+Ctrl+9".action.move-column-to-workspace = 9;
          "Mod+Ctrl+0".action.move-column-to-workspace = 10;

          # Move to workspace and follow
          "Mod+Shift+1".action.move-window-to-workspace = 1;
          "Mod+Shift+2".action.move-window-to-workspace = 2;
          "Mod+Shift+3".action.move-window-to-workspace = 3;
          "Mod+Shift+4".action.move-window-to-workspace = 4;
          "Mod+Shift+5".action.move-window-to-workspace = 5;
          "Mod+Shift+6".action.move-window-to-workspace = 6;
          "Mod+Shift+7".action.move-window-to-workspace = 7;
          "Mod+Shift+8".action.move-window-to-workspace = 8;
          "Mod+Shift+9".action.move-window-to-workspace = 9;
          "Mod+Shift+0".action.move-window-to-workspace = 10;

          # Window operations
          "Mod+Q".action.close-window = { };
          "Mod+F".action.maximize-column = { };
          "Mod+Shift+F".action.fullscreen-window = { };

          # Column width
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+R".action.switch-preset-column-width = { };
          "Mod+Shift+R".action.switch-preset-window-height = { };

          # Column positioning
          "Mod+C".action.center-column = { };
          "Mod+Ctrl+C".action.center-visible-columns = { };
          "Mod+Ctrl+F".action.expand-column-to-available-width = { };

          # Quick jumps
          "Mod+Home".action.focus-column-first = { };
          "Mod+End".action.focus-column-last = { };

          # Screenshots
          "Mod+Shift+S".action.spawn = [
            "bash"
            "-c"
            "grim -g \"$(slurp)\" - | wl-copy"
          ];
          "Mod+Shift+A".action.spawn = [
            "bash"
            "-c"
            "grim - | wl-copy"
          ];

          # Exit
          "Mod+Shift+E".action.quit = { };
        };

        # Window rules
        window-rules = [
          {
            matches = [
              { app-id = "1password"; }
            ];
            default-column-width = {
              proportion = 0.25;
            };
          }
          {
            matches = [
              { app-id = "vesktop"; }
            ];
            default-column-width = {
              proportion = 0.25;
            };
          }
          # Steam windows - main interface and friends list
          {
            matches = [
              { app-id = "^steam$"; }
              { title = "^Steam$"; }
              { title = "^Friends List$"; }
            ];
            default-column-width = {
              proportion = 0.5;
            };
          }
          # Steam game windows - allow fullscreen
          {
            matches = [
              { app-id = "^steam_app_.*"; }
            ];
            open-fullscreen = true;
          }
          # Gamescope - Steam's gaming compositor
          {
            matches = [
              { app-id = "^gamescope$"; }
            ];
            open-fullscreen = true;
          }
          #   # EasyEffects - Audio effects manager
          #   {
          #     matches = [
          #       { app-id = "com.github.wwmm.easyeffects"; }
          #     ];
          #     open-on-workspace = "2";
          #   }
          #   # PavuControl - Volume control
          #   {
          #     matches = [
          #       { app-id = "org.pulseaudio.pavucontrol"; }
          #     ];
          #     open-on-workspace = "2";
          #   }

          # DMS / Quickshell windows - float by default
          {
            matches = [
              { app-id = "^org\\.quickshell$"; }
            ];
            open-floating = true;
          }
        ];

        layer-rules = [
          # Let DMS place wallpapers/blur layers into the Overview/backdrop.
          {
            matches = [
              { namespace = "^quickshell$"; }
            ];
            place-within-backdrop = true;
          }
          {
            matches = [
              { namespace = "dms:blurwallpaper"; }
            ];
            place-within-backdrop = true;
          }
        ];

        # Animations
        animations = {
          slowdown = 2.5;

          window-open = {
            # duration-ms = 400;
            custom-shader = ''
               vec4 pixelate_open(vec3 coords_geo, vec3 size_geo) {
                  // Discard pixels outside window bounds
                  if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                      return vec4(0.0);
                  }
                  float progress = niri_clamped_progress;
                  float border_width = 0.008; // Adjust based on your border size
                  vec2 coords = coords_geo.xy;
                  // Check if we're in the border region
                  bool in_border = coords.x < border_width || coords.x > (1.0 - border_width) ||
                                  coords.y < border_width || coords.y > (1.0 - border_width);
                  // Only pixelate the inner content, not the border
                  if (!in_border) {
                      float pixel_size = (1.0 - progress) * 0.1;
                      if (pixel_size > 0.0) {
                          coords = floor(coords / pixel_size) * pixel_size + pixel_size * 0.5;
                      }
                      // Clamp sampling to avoid border area
                      coords = clamp(coords, border_width, 1.0 - border_width);
                  }
                  vec3 new_coords = vec3(coords, 1.0);
                  vec3 coords_tex = niri_geo_to_tex * new_coords;
                  vec4 color = texture2D(niri_tex, coords_tex.st);
                  color.a *= progress;
                  return color;
              }
              vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                return pixelate_open(coords_geo, size_geo);
              }
            '';
          };

          window-close = {
            # duration-ms = 400;
            custom-shader = ''
               vec4 pixelate_close(vec3 coords_geo, vec3 size_geo) {
                  // Discard pixels outside window bounds
                  if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0) {
                      return vec4(0.0);
                  }
                  float progress = niri_clamped_progress;
                  float border_width = 0.008;
                  vec2 coords = coords_geo.xy;
                  // Check if we're in the border region
                  bool in_border = coords.x < border_width || coords.x > (1.0 - border_width) ||
                                  coords.y < border_width || coords.y > (1.0 - border_width);
                  // Only pixelate the inner content, not the border
                  if (!in_border) {
                      float pixel_size = progress * 0.1;
                      if (pixel_size > 0.0) {
                          coords = floor(coords / pixel_size) * pixel_size + pixel_size * 0.5;
                      }
                      // Clamp sampling to avoid border area
                      coords = clamp(coords, border_width, 1.0 - border_width);
                  }
                  vec3 new_coords = vec3(coords, 1.0);
                  vec3 coords_tex = niri_geo_to_tex * new_coords;
                  vec4 color = texture2D(niri_tex, coords_tex.st);
                  color.a *= (1.0 - progress);
                  return color;
              }
              vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                return pixelate_close(coords_geo, size_geo);
              }
            '';
          };
        };

        # Startup programs
        # Note: wallpaper is managed by DankMaterialShell
        spawn-at-startup = [
          # Solaar applies saved Logitech mouse settings (scroll diversion off)
          # This fixes scroll wheel after KVM switch
          {
            command = [
              "solaar"
              "-w"
              "hide"
            ];
          }
        ];

        prefer-no-csd = true;
      };

    }
  ];
}
