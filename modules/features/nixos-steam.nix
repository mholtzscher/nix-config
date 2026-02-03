# NixOS Steam module
# Steam, gamemode, and gaming performance tuning
{ config, lib, ... }:
let
  cfg = config.myFeatures.nixosSteam;
in
{
  options.myFeatures.nixosSteam = {
    enable = lib.mkEnableOption "NixOS Steam support" // {
      default = true;
      description = "Steam and gaming performance configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.nixos.steam = {
      programs = {
        steam = {
          enable = true;
          remotePlay.openFirewall = false;
          dedicatedServer.openFirewall = false;
          localNetworkGameTransfers.openFirewall = false;
          gamescopeSession.enable = true;
        };

        # Enable gamemode for performance optimizations during gaming
        gamemode.enable = true;
      };

      # Performance tuning for gaming
      powerManagement.cpuFreqGovernor = "performance";

      # Increase vm.max_map_count for games that need it (some Proton games)
      boot.kernel.sysctl = {
        "vm.max_map_count" = 2147483642;
      };
    };
  };
}
