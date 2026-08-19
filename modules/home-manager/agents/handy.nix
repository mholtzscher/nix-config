{
  pkgs,
  inputs,
  lib,
  isWork,
  ...
}:
{
  home.packages = lib.optional (!isWork) [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.handy
  ];
}
