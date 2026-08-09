let
  recipients = import ./recipients.nix;
in
{
  "agent-artifacts-write-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "atuin-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "dummy-env.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "nixos-desktop-cloudflare-tunnel-token.age".publicKeys = [ recipients."nixos-desktop" ];
  "opencode-go-cookie.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "opencode-go-workspace-id.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "sideshow-token.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
}
