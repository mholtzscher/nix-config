{
  lib,
  isDarwin,
  isWork ? false,
  ...
}:
{
  # Personal Macs use the native Tailscale app through Mise.
  # Keep the system daemon on personal/non-work Linux systems.
  # Initial auth still happens out-of-band with `sudo tailscale up` so no
  # auth keys or secrets are stored in the Nix store.
  services.tailscale = {
    enable = lib.mkIf (!isWork && !isDarwin) true;
    # extraSetFlags = [ "--operator=michael" ];
  };
}
