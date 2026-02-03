# NixOS Steam module
# Steam, gamemode, and gaming performance tuning
{
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
}
