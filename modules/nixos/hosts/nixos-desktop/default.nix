{ pkgs, ... }:
{
  # NixOS Desktop Environment Configuration
  # This module provides a complete desktop environment setup including:
  # - Niri window manager + DankMaterialShell integration
  # - Gaming tools and configuration
  # - Theming (GTK, Qt, dark mode)
  # - Web applications as native apps

  imports = [
    ./packages.nix # Desktop packages, fonts, 1Password
    ./composition.nix # Niri window manager + DMS keybinds/integration
    ./gaming.nix # Gaming tools (Steam, MangoHud, etc.)
    ./webapps.nix # Web applications as native apps
  ];

  # Keep PI WEB bound to localhost and expose it through the remotely managed
  # Cloudflare Tunnel. Cloudflare Access protects the public hostname.
  systemd.services.pi-web-cloudflare-tunnel = {
    description = "Cloudflare Tunnel for PI WEB";
    after = [
      "home-manager-michael.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "michael";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file /home/michael/.local/share/agenix/nixos-desktop-cloudflare-tunnel-token";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

}
