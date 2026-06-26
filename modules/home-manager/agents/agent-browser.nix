{
  pkgs,
  lib,
  inputs,
  isWork,
  ...
}:
{
  home.packages = lib.optionals (!isWork) [
    # inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agent-browser
  ];
}
