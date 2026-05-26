{
  lib,
  isWork ? false,
  ...
}:
{
  # Enable Tailscale on personal/non-work systems.
  # Initial auth still happens out-of-band with `sudo tailscale up` so no
  # auth keys or secrets are stored in the Nix store.
  services.tailscale.enable = lib.mkIf (!isWork) true;
}
