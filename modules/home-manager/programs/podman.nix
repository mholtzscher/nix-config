{ isWork, isDarwin, ... }:
{
  # Macs use Docker Desktop via Mise; retain Podman on non-work Linux hosts.
  services.podman.enable = !isWork && !isDarwin;
}
