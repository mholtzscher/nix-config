{
  pkgs,
  lib,
  inputs,
  isWork,
  ...
}:
let
  filteredExtensionsSource = builtins.path {
    path = ./files/pi/extensions;
    name = "pi-extensions";
    filter = path: type: type == "directory" || lib.hasSuffix ".ts" (builtins.baseNameOf path);
  };
in
{
  home.packages = lib.optionals (!isWork) [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  home.file = lib.optionalAttrs (!isWork) {
    ".pi/agent/settings.json".text = builtins.toJSON {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      theme = "oh-p-dark";
      workingVibe = "Bruce Schneier";
      workingVibeMode = "file";
      packages = [
        "npm:@ifi/oh-pi-themes"
        "npm:@plannotator/pi-extension"
        "npm:glimpseui"
        "npm:pi-btw"
        "npm:pi-fff"
        "npm:pi-interview"
        "npm:pi-powerline-footer"
        "npm:pi-web-access"
      ];
      npmCommand = [
        "mise"
        "exec"
        "node@24"
        "--"
        "npm"
      ];
    };

    ".pi/agent/prompts" = {
      source = ./files/pi/prompts;
      recursive = true;
    };

    ".pi/web-search.json".text = builtins.toJSON {
      workflow = "none";
    };

    ".pi/agent/models.json".text = builtins.toJSON {
      providers = {
        llama-cpp = {
          baseUrl = "http://127.0.0.1:8081/v1";
          api = "openai-completions";
          apiKey = "llama-cpp";
          compat = {
            supportsDeveloperRole = true;
            supportsReasoningEffort = false;
          };
          models = [
            {
              id = "local";
              name = "Local Model";
              reasoning = true;
              input = [
                "text"
                "image"
              ];
              contextWindow = 131072;
              maxTokens = 81920;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };
      };
    };

    ".pi/agent/extensions" = {
      source = filteredExtensionsSource;
      recursive = true;
    };

    ".pi/agent/vibes" = {
      source = ./files/pi/vibes;
      recursive = true;
    };
  };
}
