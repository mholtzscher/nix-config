{
  pkgs,
  lib,
  config,
  ...
}:

let
  # llama.cpp with CUDA acceleration (requires NVIDIA GPU + drivers)
  llama-cpp-cuda = pkgs.llama-cpp.override { cudaSupport = true; };

  llamaServerWrapper = pkgs.writeShellScriptBin "llama-server-wrapper" ''
    exec ${llama-cpp-cuda}/bin/llama-server \
      -m /home/michael/models/unsloth/Qwen3.6-27B-GGUF/Qwen3.6-27B-UD-Q4_K_XL.gguf \
      --mmproj /home/michael/models/unsloth/Qwen3.6-27B-GGUF/mmproj-F16.gguf \
      --alias local \
      --host 0.0.0.0 \
      --port 8081 \
      --temp 0.6 \
      --top-p 0.95 \
      --top-k 20 \
      --min-p 0.00 \
      --kv-unified \
      --cache-type-k q8_0 \
      --cache-type-v q8_0 \
      --flash-attn on \
      --fit on \
      --ctx-size 131072
  '';
in {
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

    ollama-cuda # Local LLM server (run on-demand: ollama serve)

    llamaServerWrapper # Convenience wrapper for serving Qwen3.6-27B (via llama.cpp CUDA)

    python313Packages.huggingface-hub # Hugging Face CLI (provides huggingface-cli) for downloading models

    # Linux desktop-specific GUI tools
    nautilus # File manager
    imv # Image viewer
    zathura # PDF viewer
    brightnessctl # Brightness control
    pavucontrol # Audio control GUI
    steam-run # Steam runtime for non-Steam applications
    qpwgraph # PipeWire graph visualizer for audio routing

    wtype # Wayland typing tool for dictation output
    libnotify # Notifications for dictation status
  ];

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
    acLockTimeout = 600; # 10 min - lock screen (recoverable via Mod+Shift+O)
    acMonitorTimeout = 720; # 12 min - DPMS display off (recoverable via Mod+Shift+O)
    acSuspendTimeout = 0; # Never auto-suspend

    # Lock behavior
    lockBeforeSuspend = true;
    fadeToLockEnabled = true;
    fadeToLockGracePeriod = 5;
    fadeToDpmsEnabled = true; # All recoverable via Mod+Shift+O if KVM wedges
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
