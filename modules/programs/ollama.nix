# Ollama - local LLM runner
# Note: This module is added per-host, not in profileCommon (excluded from work machines)
{
  flake.modules.homeManager.ollama =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ollama ];
    };
}
