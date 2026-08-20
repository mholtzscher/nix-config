{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  downloadUltrawideWallpapers = pkgs.writeShellApplication {
    name = "download-ultrawide-wallpapers";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gnugrep
    ];
    text = ''
      base_url="https://ultrawidewallpapers.net"
      destination="$HOME/Pictures/wallpapers"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/ultrawide-wallpapers"
      checkpoint="$state_dir/checkpoint"
      gallery="$(mktemp)"
      cookie_jar="$(mktemp)"
      temporary=""
      trap 'rm -f "$gallery" "$cookie_jar" "$temporary"' EXIT
      curl_args=(
        --fail
        --silent
        --show-error
        --location
        --retry 5
        --retry-all-errors
        --retry-delay 10
        --user-agent "Mozilla/5.0"
      )

      curl "''${curl_args[@]}" --cookie-jar "$cookie_jar" \
        "$base_url/gallery.php" \
        --output /dev/null
      curl "''${curl_args[@]}" --cookie "$cookie_jar" \
        "$base_url/gallery_load.php?offset=0&limit=200" \
        --output "$gallery"

      mapfile -t wallpapers < <(
        grep -o 'href="wallpapers/329/highres/[A-Za-z0-9._-]*"' "$gallery" \
          | cut -d '"' -f 2
      )
      if (( ''${#wallpapers[@]} == 0 )); then
        echo "No wallpapers found in gallery response" >&2
        exit 1
      fi

      mkdir -p "$destination" "$state_dir"
      newest="''${wallpapers[0]}"
      if [[ ! -f "$checkpoint" ]]; then
        printf '%s\n' "$newest" > "$checkpoint"
        echo "Initialized checkpoint at ''${newest##*/}; no files downloaded"
        exit 0
      fi

      previous="$(<"$checkpoint")"
      new_wallpapers=()
      found_checkpoint=false
      for wallpaper in "''${wallpapers[@]}"; do
        if [[ "$wallpaper" == "$previous" ]]; then
          found_checkpoint=true
          break
        fi
        new_wallpapers+=("$wallpaper")
      done

      if [[ "$found_checkpoint" != true ]]; then
        echo "Previous checkpoint is not among the 200 newest wallpapers; refusing to guess" >&2
        exit 1
      fi

      for ((i = ''${#new_wallpapers[@]} - 1; i >= 0; i--)); do
        wallpaper="''${new_wallpapers[i]}"
        filename="''${wallpaper##*/}"
        target="$destination/$filename"
        if [[ -e "$target" ]]; then
          echo "Already exists: $filename"
          continue
        fi

        temporary="$(mktemp "$destination/.$filename.XXXXXX")"
        content_type="$(
          curl "''${curl_args[@]}" \
            --cookie "$cookie_jar" \
            --referer "$base_url/gallery.php" \
            --write-out '%{content_type}' \
            "$base_url/$wallpaper" \
            --output "$temporary"
        )"
        if [[ "$content_type" != image/* ]]; then
          rm -f "$temporary"
          echo "Unexpected content type for $filename: $content_type" >&2
          exit 1
        fi
        chmod 0644 "$temporary"
        mv "$temporary" "$target"
        echo "Downloaded: $filename"
        sleep 2
      done

      printf '%s\n' "$newest" > "$checkpoint"
      echo "Checkpoint updated to ''${newest##*/}"
    '';
  };
  ecowittPlugin = pkgs.linkFarm "noctalia-ecowitt-plugin" [
    {
      name = "ecowitt";
      path = ./ecowitt;
    }
  ];
in
{
  imports = [
    inputs.noctalia.homeModules.default
    ./voxtype.nix
  ];

  # NixOS Desktop-specific home-manager configuration
  # Desktop environment setup is now in modules/nixos/desktop/
  # This file contains only user-specific packages and services

  # Niri configuration is validated by Home Manager at build time.
  wayland.windowManager.niri = {
    enable = true;
    # NixOS owns niri.service; Home Manager provides xwayland-satellite.
    systemd.enable = false;
    portalPackage = null;
    extraConfig = builtins.readFile ./niri.kdl;
  };

  programs.noctalia = {
    enable = true;
    settings = {
      wallpaper = {
        directory = "${config.home.homeDirectory}/Pictures/wallpapers";
        automation = {
          enabled = true;
          interval_seconds = 1800;
        };
      };
      theme = {
        source = "builtin";
        builtin = "Catppuccin";
      };
      plugins = {
        source = [
          {
            name = "ecowitt-local";
            kind = "path";
            location = "${ecowittPlugin}";
            enabled = true;
          }
        ];
        enabled = [ "michael/ecowitt" ];
      };
      bar.main = {
        position = "top";
        thickness = 34;
        margin_ends = 1450;
        margin_edge = 8;
        auto_hide = false;
        smart_auto_hide = true;
        show_on_workspace_switch = true;
        reserve_space = false;
        layer = "top";
        start = [
          "launcher"
          "media"
          "ecowitt"
        ];
        center = [ "workspaces" ];
        end = [
          "tray"
          "notifications"
          "volume"
          "clock"
          "control-center"
        ];
      };
      shell = {
        time_format = "{:%-I:%M %p}";
        panel_anchor_bar = "main";
        panel = {
          launcher_placement = "floating";
          launcher_position = "center";
          clipboard_placement = "floating";
          clipboard_position = "center";
          control_center_placement = "attached";
          wallpaper_placement = "attached";
          session_placement = "attached";
        };
      };
      widget.clock.format = "{:%-I:%M %p}";
      widget.ecowitt = {
        type = "michael/ecowitt:weather";
      };
      location = {
        auto_locate = false;
        latitude = 39.273669;
        longitude = -94.517765;
      };
      weather = {
        enabled = true;
        unit = "imperial";
      };
      notification = {
        position = "top_center";
        offset_y = 8;
      };
      osd = {
        position = "top_center";
        position_vertical = "top_center";
      };
    };
  };

  # Solaar config for Logitech MX Master 3S
  # Key setting: scroll diversion OFF to fix scrolling after KVM switch
  xdg.configFile."solaar/config.yaml".text = lib.generators.toYAML { } [
    "1.1.16"
    {
      _NAME = "MX Master 3S for Mac";
      _modelId = "B03400000000";
      _serial = "6EBEDCC2";
      _unitId = "6EBEDCC2";
      _wpid = "B034";
      # Scroll diversion OFF - fixes scroll wheel after KVM switch
      hires-scroll-mode = false;
      thumb-scroll-mode = false;
      # Other scroll settings
      hires-smooth-invert = false;
      hires-smooth-resolution = false;
      thumb-scroll-invert = false;
      scroll-ratchet = 2;
      smart-shift = 12;
      # DPI
      dpi = 1000;
    }
  ];

  # Desktop-specific programs and packages
  home.packages = with pkgs; [
    awscli2 # AWS command-line interface
    gnused
    localsend # Local network file sharing
    vesktop # Discord client with better Wayland support

    python313Packages.huggingface-hub # Hugging Face CLI (provides huggingface-cli) for downloading models

    # Linux desktop-specific GUI tools
    nautilus # File manager
    imv # Image viewer
    zathura # PDF viewer
    brightnessctl # Brightness control
    pavucontrol # Audio control GUI
    steam-run # Steam runtime for non-Steam applications
    qpwgraph # PipeWire graph visualizer for audio routing
  ];

  # Audio effects processing for microphone and system audio
  services.easyeffects.enable = true;

  systemd.user.services.download-ultrawide-wallpapers = {
    Unit.Description = "Download new weekly ultrawide wallpapers";
    Service = {
      Type = "oneshot";
      ExecStart = "${downloadUltrawideWallpapers}/bin/download-ultrawide-wallpapers";
    };
  };

  systemd.user.timers.download-ultrawide-wallpapers = {
    Unit.Description = "Check for new ultrawide wallpapers every Monday";
    Timer = {
      OnCalendar = "Mon *-*-* 06:00:00 America/Chicago";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services."1password" = {
    Unit = {
      Description = "1Password";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
