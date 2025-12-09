# Native NixOS services for Wanda
# These replace Docker containers with better system integration
# Data stored in /var/lib/<service> (NixOS default)
{ ... }:
{
  services = {
    # Plex Media Server
    # Data: /var/lib/plex
    plex = {
      enable = true;
      openFirewall = true;
      user = "michael";
      group = "media";
    };

    # Tautulli - Plex monitoring
    # Data: /var/lib/tautulli
    tautulli = {
      enable = true;
      openFirewall = true;
      port = 8181;
      user = "michael";
      group = "media";
    };

    # Radarr - Movie management
    # Data: /var/lib/radarr/.config/Radarr
    radarr = {
      enable = true;
      openFirewall = true;
      user = "michael";
      group = "media";
    };

    # Sonarr - TV show management
    # Data: /var/lib/sonarr/.config/Sonarr
    sonarr = {
      enable = true;
      openFirewall = true;
      user = "michael";
      group = "media";
    };

    # Prowlarr - Indexer management
    # Data: /var/lib/prowlarr/.config/Prowlarr
    prowlarr = {
      enable = true;
      openFirewall = true;
    };

    # Bazarr - Subtitle management
    # Data: /var/lib/bazarr
    bazarr = {
      enable = true;
      openFirewall = true;
      user = "michael";
      group = "media";
    };

    # Overseerr - Request management
    # Data: /var/lib/overseerr
    overseerr = {
      enable = true;
      openFirewall = true;
    };

    # Kavita - Book/comic server
    # Data: /var/lib/kavita
    kavita = {
      enable = true;
      user = "michael";
      tokenKeyFile = "/var/lib/kavita/token-key";
    };
  };

  # Kavita doesn't have openFirewall option, open port manually
  networking.firewall.allowedTCPPorts = [ 5000 ];
}
