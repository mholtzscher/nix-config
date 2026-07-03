let
  recipients = import ./recipients.nix;
in
{
  "dummy-env.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
}
