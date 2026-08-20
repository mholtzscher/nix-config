{
  pkgs,
  inputs,
  lib,
  isWork,
  currentSystemName,
  ...
}:
{
  home.packages = lib.optionals (!isWork && currentSystemName != "nixos-desktop") [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.handy
  ];
}
