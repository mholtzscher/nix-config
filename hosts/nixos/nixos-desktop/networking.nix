{ ... }:
{
  # Enable NetworkManager for easy network management
  networking = {
    hostName = "nixos-desktop";
    networkmanager.enable = true;

    # Firewall configuration
    firewall = {
      enable = true;
      # Only allow SSH from local network (10.69.69.0/24) and Tailscale (100.64.0.0/10)
      extraCommands = ''
        iptables -A nixos-fw -p tcp --dport 22 -s 10.69.69.0/24 -j nixos-fw-accept
        iptables -A nixos-fw -p tcp --dport 22 -s 100.64.0.0/10 -j nixos-fw-accept
      '';
    };
  };

  # SSH server configuration
  services.openssh = {
    enable = true;

    # Don't auto-open port 22 globally — we manage SSH access via firewall extraCommands
    openFirewall = false;

    # Security settings - key-based authentication only
    settings = {
      PasswordAuthentication = false; # Disable password login
      PermitRootLogin = "no"; # Disable root login
      KbdInteractiveAuthentication = false; # Disable keyboard-interactive auth

      # Disable X11 forwarding (not needed for Wayland)
      X11Forwarding = false;

      # Only allow specific user
      AllowUsers = [ "michael" ];
    };

    # Port configuration - using standard port 22
    # Change to custom port (e.g., 2222) for additional security if desired
    ports = [ 22 ];
  };
}
