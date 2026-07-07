let
  recipients = import ./recipients.nix;
in
{
  "atuin-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "dummy-env.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "sideshow-token.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
}
