{
  pkgs,
  inputs,
  isWork,
  lib,
  ...
}:
{
  home.packages = lib.optionals (!isWork) [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.copilot-cli
  ];
}
