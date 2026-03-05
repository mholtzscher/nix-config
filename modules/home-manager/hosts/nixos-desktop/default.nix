{
  pkgs,
  lib,
  config,
  ...
}:
{
  # NixOS Desktop-specific home-manager configuration
  # Desktop environment setup is now in modules/nixos/desktop/
  # This file contains only user-specific packages and services

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
    vesktop # Discord client with better Wayland support

    # Linux desktop-specific GUI tools
    nautilus # File manager
    imv # Image viewer
    zathura # PDF viewer
    brightnessctl # Brightness control
    pavucontrol # Audio control GUI
    steam-run # Steam runtime for non-Steam applications
    qpwgraph # PipeWire graph visualizer for audio routing

    # Dictation tools - local speech-to-text
    whisper-cpp-vulkan # Fast local Whisper with GPU acceleration
    wtype # Wayland typing tool for dictation output
    libnotify # Notifications for dictation status
  ];

  # Dictation script: record audio -> transcribe with whisper.cpp -> type text
  home.file."bin/dictate" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Dictation script using whisper.cpp - fast local speech-to-text

      set -euo pipefail

      CONFIG_DIR="$HOME/.config/dictation"
      MODEL_DIR="$CONFIG_DIR/models"
      PID_FILE="$CONFIG_DIR/dictation.pid"
      REC_FILE="$CONFIG_DIR/current_recording"

      LANG_CODE="''${DICTATION_LANG:-en}"
      DEFAULT_MODEL="''${DICTATION_MODEL_BASENAME:-ggml-base.en.bin}"
      MODEL_PATH="''${DICTATION_MODEL_PATH:-$MODEL_DIR/$DEFAULT_MODEL}"

      notify() {
        if command -v notify-send >/dev/null 2>&1; then
          notify-send "Dictation" "$1"
        else
          printf '%s\n' "$1" >&2
        fi
      }

      download_model() {
        # Default to HuggingFace mirror for whisper.cpp ggml models.
        local url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$DEFAULT_MODEL"

        if command -v curl >/dev/null 2>&1; then
          curl -fsSL "$url" -o "$MODEL_PATH"
          return
        fi

        if command -v wget >/dev/null 2>&1; then
          wget -qO "$MODEL_PATH" "$url"
          return
        fi

        notify "Missing downloader (curl/wget)"
        exit 1
      }

      trim() {
        # shellcheck disable=SC2001
        local s="$1"
        s=''${s#"''${s%%[![:space:]]*}"}
        s=''${s%"''${s##*[![:space:]]}"}
        printf '%s' "$s"
      }

      mkdir -p "$MODEL_DIR"

      if [ ! -f "$MODEL_PATH" ]; then
        notify "Downloading Whisper model (one-time)..."
        if ! download_model; then
          notify "Model download failed"
          exit 1
        fi
        notify "Model ready"
      fi

      if ! command -v pw-record >/dev/null 2>&1; then
        notify "Missing pw-record (PipeWire)"
        exit 1
      fi
      if ! command -v whisper-cli >/dev/null 2>&1; then
        notify "Missing whisper-cli"
        exit 1
      fi
      if ! command -v wtype >/dev/null 2>&1; then
        notify "Missing wtype"
        exit 1
      fi

      if [ -f "$PID_FILE" ]; then
        pid="$(<"$PID_FILE" 2>/dev/null || true)"
        audio_file="$(<"$REC_FILE" 2>/dev/null || true)"

        rm -f "$PID_FILE" "$REC_FILE"

        if [ -z "$pid" ] || [ -z "$audio_file" ]; then
          notify "No active recording"
          exit 0
        fi

        if kill -0 "$pid" 2>/dev/null; then
          kill "$pid" 2>/dev/null || true
          wait "$pid" 2>/dev/null || true
        fi

        if [ ! -s "$audio_file" ]; then
          notify "No audio captured"
          rm -rf "$(dirname "$audio_file")" 2>/dev/null || true
          exit 1
        fi

        tmpdir="$(dirname "$audio_file")"
        err_file="$tmpdir/whisper.err"

        notify "Transcribing..."

        text="$(whisper-cli -m "$MODEL_PATH" -f "$audio_file" -l "$LANG_CODE" -nt -np 2>"$err_file" || true)"
        text=''${text//$'\r'/}
        text=''${text//$'\n'/ }
        text=''${text//$'\t'/ }
        text="$(trim "$text")"

        if [ -z "$text" ]; then
          if [ -s "$err_file" ]; then
            last_err="$CONFIG_DIR/last-whisper.err"
            cp "$err_file" "$last_err" 2>/dev/null || true
            notify "Transcribe failed (see $last_err)"
          else
            notify "No speech detected"
          fi
          rm -rf "$tmpdir" 2>/dev/null || true
          exit 1
        fi

        wtype "$text"
        notify "Done"

        rm -rf "$tmpdir" 2>/dev/null || true
        exit 0
      fi

      tmpdir="$(mktemp -d)"
      audio_file="$tmpdir/recording.wav"

      pw-record --rate=16000 --channels=1 --format=s16 "$audio_file" &
      pid=$!

      printf '%s\n' "$pid" > "$PID_FILE"
      printf '%s\n' "$audio_file" > "$REC_FILE"

      # Give pw-record a moment; fail fast if it exits immediately.
      sleep 0.05
      if ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$PID_FILE" "$REC_FILE"
        rm -rf "$tmpdir" 2>/dev/null || true
        notify "Recording failed (pw-record exited)"
        exit 1
      fi

      notify "Recording... (press hotkey again to stop)"
    '';
  };

  # DankMaterialShell theme (Catppuccin Mocha + Lavender accent)
  xdg.configFile."DankMaterialShell/themes/catppuccin-mocha-lavender.json".source =
    ../../files/dms/catppuccin-mocha-lavender.json;

  xdg.configFile."DankMaterialShell/settings.json".text = builtins.toJSON {
    currentThemeName = "custom";
    customThemeFile = "${config.xdg.configHome}/DankMaterialShell/themes/catppuccin-mocha-lavender.json";
    fontFamily = "Iosevka Nerd Font";
    useFahrenheit = true;
    use24HourClock = false;

    # Idle Management (desktop - AC power only)
    acLockTimeout = 600; # 10 min - lock screen
    acMonitorTimeout = 720; # 12 min - turn off display
    acSuspendTimeout = 0; # Never auto-suspend

    # Lock behavior
    lockBeforeSuspend = true;
    fadeToLockEnabled = true;
    fadeToLockGracePeriod = 5;
    fadeToDpmsEnabled = true;
    fadeToDpmsGracePeriod = 5;
  };

  # Audio effects processing for microphone and system audio
  services.easyeffects.enable = true;

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
