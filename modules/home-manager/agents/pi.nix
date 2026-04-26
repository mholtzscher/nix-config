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
    ".pi/agent/settings.json".source = ./files/pi/settings.json;

    ".pi/agent/prompts" = {
      source = ./files/pi/prompts;
      recursive = true;
    };

    ".pi/agent/extensions" = {
      source = filteredExtensionsSource;
      recursive = true;
    };
  };
}
