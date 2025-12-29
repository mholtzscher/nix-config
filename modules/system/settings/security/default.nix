{ inputs, ... }:
{
  # Security settings for NixOS hosts

  flake.modules.nixos.security =
    { lib, ... }:
    {
      security.sudo.wheelNeedsPassword = true;

      # Fail2ban for brute-force protection
      services.fail2ban = {
        enable = true;
        maxretry = 5;
        ignoreIP = [
          "127.0.0.1/8"
          "10.69.69.0/24"
        ];
      };

      # Enable zram swap
      zramSwap.enable = lib.mkDefault true;
    };
}
