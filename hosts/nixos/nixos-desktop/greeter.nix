{ ... }:
{
  # The standalone greeter starts user services such as WirePlumber, which need
  # a writable home instead of greetd's default /var/empty.
  users.users.greeter.home = "/var/lib/dms-greeter";

  # DankLinux's docs only describe ownership of the top-level greeter cache.
  # The standalone greeter additionally requires these hidden XDG directories
  # with mode 2770, but its NixOS module does not create them. Its pre-start
  # chown also uses `*`, which skips hidden directories and cannot repair them.
  systemd.tmpfiles.settings."10-dms-greeter" = {
    "/var/lib/dms-greeter/.cache".d = {
      user = "greeter";
      group = "greeter";
      mode = "2770";
    };
    "/var/lib/dms-greeter/.local/state".d = {
      user = "greeter";
      group = "greeter";
      mode = "2770";
    };
    "/var/lib/dms-greeter/.local/share".d = {
      user = "greeter";
      group = "greeter";
      mode = "2770";
    };
  };

  # DMS (Dank Material Shell) greeter via greetd
  # Runs the login screen under Niri with an explicit greeter-time config.
  programs.dms-greeter = {
    enable = true;

    compositor = {
      name = "niri";

      # This runs before the user session (no home-manager), so keep outputs deterministic.
      customConfig = ''
        hotkey-overlay {
          skip-at-startup
        }

        environment {
          DMS_RUN_GREETER "1"
        }

        gestures {
          hot-corners {
            off
          }
        }

        output "DP-1" {
          mode "5120x1440@120"
          scale 1
          position x=0 y=0
        }

        layout {
          background-color "#000000"
        }
      '';
    };

    # Copy the user's DMS config into /var/lib/dms-greeter for theme/wallpaper sync.
    configHome = "/home/michael";

    logs = {
      save = false;
      path = "/var/log/dms-greeter.log";
    };
  };
}
