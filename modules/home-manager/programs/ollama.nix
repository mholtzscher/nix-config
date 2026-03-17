{
  pkgs,
  lib,
  isWork,
  currentSystemName,
  ...
}:
{
  config = lib.mkIf (!isWork && currentSystemName != "nixos-desktop") {
    # Install ollama package on non-work machines without a system ollama service
    # Run on-demand with: ollama serve
    home.packages = [ pkgs.ollama ];
  };
}
