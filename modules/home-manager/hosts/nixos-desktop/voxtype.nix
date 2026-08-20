{ pkgs, ... }:

let
  voxtype = pkgs.voxtype-vulkan;
  downloadVoxtypeModels = pkgs.writeShellApplication {
    name = "download-voxtype-models";
    runtimeInputs = with pkgs; [
      coreutils
      curl
    ];
    text = ''
      models_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/voxtype/models"

      download_model() {
        local filename="$1"
        local url="$2"
        local checksum="$3"
        local model="$models_dir/$filename"
        local temporary="$model.part"

        if [[ -s "$model" ]]; then
          return
        fi

        curl \
          --fail \
          --location \
          --retry 5 \
          --retry-all-errors \
          --continue-at - \
          --output "$temporary" \
          "$url"
        if ! printf '%s  %s\n' "$checksum" "$temporary" \
          | sha256sum --check --status; then
          rm -f "$temporary"
          echo "Downloaded Voxtype model failed checksum verification: $filename" >&2
          exit 1
        fi
        mv "$temporary" "$model"
      }

      mkdir -p "$models_dir"
      download_model \
        "ggml-large-v3-turbo.bin" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin" \
        "1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69"
      download_model \
        "ggml-silero-vad.bin" \
        "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin" \
        "2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987"
    '';
  };
in
{
  home.packages = [
    voxtype
    pkgs.wtype
    pkgs.libnotify
  ];

  xdg.configFile."voxtype/config.toml".text = ''
    engine = "whisper"
    state_file = "auto"

    [hotkey]
    enabled = true
    key = "EVTEST_21"
    modifiers = ["LEFTCTRL", "LEFTSHIFT", "LEFTALT"]
    mode = "push_to_talk"

    [audio]
    device = "default"
    sample_rate = 16000
    max_duration_secs = 120

    [whisper]
    model = "large-v3-turbo"
    language = "auto"
    translate = false
    on_demand_loading = false

    [output]
    mode = "type"
    fallback_to_clipboard = true
    type_delay_ms = 0

    [vad]
    enabled = true
    backend = "whisper"
    threshold = 0.5
    min_speech_duration_ms = 100

    [output.notification]
    on_recording_start = true
    on_recording_stop = true
    on_transcription = false

    # Nixpkgs does not currently install either graphical OSD frontend.
    [osd]
    enabled = false
  '';

  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype push-to-talk voice-to-text daemon";
      After = [
        "graphical-session.target"
        "pipewire.service"
        "pipewire-pulse.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${downloadVoxtypeModels}/bin/download-voxtype-models";
      ExecStart = "${voxtype}/bin/voxtype -q daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
