{
  pkgs,
  lib,
  isWork,
  ...
}:
{
  config = lib.mkIf (!isWork) {
    # Install ollama package on all non-work machines
    # Run on-demand with: ollama serve
    home.packages = [ pkgs.ollama ];
  };
}
