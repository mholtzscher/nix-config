{ isWork, ... }:
{
  services.podman.enable = !isWork;
}
