{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.bonsai;

  bonsaiLlamaCpp = pkgs.callPackage ../../../../pkgs/bonsai-llama-cpp { };

  hfRepo = "prism-ml/Ternary-Bonsai-2-27B-gguf";

  modelFile =
    {
      PQ2_0 = "Ternary-Bonsai-2-27B-PQ2_0.gguf";
      PTQ1_0 = "Ternary-Bonsai-2-27B-PTQ1_0.gguf";
    }
    .${cfg.packing};

  mmprojFile = "Ternary-Bonsai-2-27B-mmproj-Q8_0.gguf";

  downloadOne = file: ''
    if [ -s "/var/lib/bonsai/${file}" ]; then
      echo "already present: ${file}"
    else
      echo "downloading ${file} ..."
      ${lib.getExe pkgs.curl} -fSL --retry 5 --retry-all-errors --retry-delay 10 \
        -o "/var/lib/bonsai/${file}.part" \
        "https://huggingface.co/${hfRepo}/resolve/main/${file}"
      mv "/var/lib/bonsai/${file}.part" "/var/lib/bonsai/${file}"
    fi
  '';

  downloadScript = pkgs.writeShellScript "bonsai-download-models" ''
    set -euo pipefail
    mkdir -p /var/lib/bonsai
    ${downloadOne modelFile}
    ${lib.optionalString cfg.enableVision (downloadOne mmprojFile)}
  '';
in
{
  options.services.bonsai = {
    enable = lib.mkEnableOption "PrismML Bonsai 2 27B local inference server (CUDA)";

    packing = lib.mkOption {
      type = lib.types.enum [
        "PQ2_0"
        "PTQ1_0"
      ];
      default = "PQ2_0";
      description = ''
        GGUF weight packing. PQ2_0 (7.21 GB) is the demo default and faster at
        prompt processing. PTQ1_0 (5.95 GB) is smaller and wins on memory-tight
        cards. Both need the Prism llama.cpp fork (packaged in pkgs/bonsai-llama-cpp);
        stock llama.cpp / Ollama cannot run them.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address for llama-server. Set to 0.0.0.0 for LAN access (see openFirewall).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      # 8080 is taken by the user's hearth dev server; 8888 avoids the clash.
      default = 8888;
      description = "Port for llama-server (web UI + OpenAI-compatible API at /v1/chat/completions).";
    };

    contextSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 131072;
      description = ''
        Context window (-c). The model supports up to 262144, but FP16 KV
        costs ~64 KiB/token (~8 GiB at 131K, ~16 GiB at full context). 131072
        is the sweet spot on the 24 GB 3090 paired with FP16 KV (~17.6 GiB
        total); 262144 only fits with quantizedKvCache and costs ~25 GiB.
      '';
    };

    quantizedKvCache = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Store the KV cache in Q4_0 instead of FP16 (~3.5x smaller, e.g. ~4.7
        GiB at 256K vs ~8 GiB at 131K for FP16). Decode is slightly slower
        and long-context quality degrades; mainly useful to reach 262144 on
        a 24 GB GPU. Upstream offers an optional mean-centering bias
        (scripts/make_kv_bias.sh in Bonsai-demo) for better q4_0 quality;
        not wired here.
      '';
    };

    gpuLayers = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 99;
      description = "Layers offloaded to GPU (-ngl). 99 = all layers. 0 = CPU-only.";
    };

    enableVision = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Download the Q8_0 mmproj projector and enable image input (--mmproj).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the firewall for cfg.port (needed for LAN access with host 0.0.0.0).";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--reasoning-budget"
        "2048"
      ];
      description = "Extra flags appended to the llama-server command line.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.bonsai-model-download = {
      description = "Download Bonsai 2 27B weights from HuggingFace";
      wantedBy = [ "multi-user.target" ];
      before = [ "bonsai-llama-server.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "bonsai";
        # Skip-if-present: re-download manually if a file is corrupt.
        ExecStart = downloadScript;
      };
    };

    systemd.services.bonsai-llama-server = {
      description = "Bonsai 2 27B inference server (Prism llama.cpp, CUDA)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "bonsai-model-download.service"
      ];
      requires = [ "bonsai-model-download.service" ];

      environment.LD_LIBRARY_PATH = "${bonsaiLlamaCpp}/lib";

      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "bonsai";
        SupplementaryGroups = [
          "video"
          "render"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
        ExecStart = lib.escapeShellArgs (
          [
            "${bonsaiLlamaCpp}/bin/llama-server"
            "-m"
            "/var/lib/bonsai/${modelFile}"
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
            "-ngl"
            (toString cfg.gpuLayers)
            "-fa"
            "on"
            "-c"
            (toString cfg.contextSize)
            # Upstream-recommended sampling for Bonsai 2 thinking mode.
            "--temp"
            "1.0"
            "--top-p"
            "0.95"
            "--top-k"
            "20"
            # Native OpenAI-style tool calling.
            "--jinja"
          ]
          ++ lib.optionals cfg.enableVision [
            "--mmproj"
            "/var/lib/bonsai/${mmprojFile}"
          ]
          ++ lib.optionals cfg.quantizedKvCache [
            "--cache-type-k"
            "q4_0"
            "--cache-type-v"
            "q4_0"
          ]
          ++ cfg.extraArgs
        );
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    # llama-cli for terminal smoke tests:
    # llama-cli -m /var/lib/bonsai/<model> -ngl 99 -fa on -c 32768 -p "..." -n 256
    environment.systemPackages = [ bonsaiLlamaCpp ];
  };
}
