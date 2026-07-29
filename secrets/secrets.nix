let
  recipients = import ./recipients.nix;
in
{
  "agent-artifacts-write-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "atuin-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "dummy-env.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "nixos-desktop-cloudflare-tunnel-token.age".publicKeys = [ recipients."nixos-desktop" ];
  "opencode-go-cookie.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "opencode-go-workspace-id.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "sideshow-token.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
}
