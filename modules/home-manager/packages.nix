{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.terminal-browser
  cachix
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  nil
  nixfmt
  statix
]
++ pkgs.lib.optionals (!isWork) [
  bruno
  tailscale
]
