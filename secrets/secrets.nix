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
  "unifi-password.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];

  # Komodo trial stack on wanda.
  "komodo-database-environment.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "komodo-init-admin-password.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "komodo-jwt-secret.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "komodo-webhook-secret.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
}
