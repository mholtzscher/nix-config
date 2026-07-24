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
  "sideshow-token.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
}
