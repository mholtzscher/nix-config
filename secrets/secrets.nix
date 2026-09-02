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
  "github-pat.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "nixos-desktop-cloudflare-tunnel-token.age".publicKeys = [ recipients."nixos-desktop" ];
  "unifi-password.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
}
