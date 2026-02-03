# NixOS Services module
# Common services: pipewire, SSH, printing
{
  flake.modules.nixos.services = {
    services = {
      # Enable sound with pipewire
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };

      # Enable CUPS for printing
      printing.enable = true;

      # SSH server configuration
      openssh = {
        enable = true;

        # Security settings - key-based authentication only
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          KbdInteractiveAuthentication = false;
          X11Forwarding = false;
          AllowUsers = [ "michael" ];
        };

        ports = [ 22 ];
      };

      # Enable mouse/touchpad input support
      libinput.enable = true;

      # Disable DPMS to prevent screen blanking issues with KVM switching
      logind.settings.Login = {
        HandlePowerKey = "ignore";
        HandleLidSwitch = "ignore";
      };
    };

    # RealtimeKit for audio
    security.rtkit.enable = true;
  };
}
