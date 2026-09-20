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
  "hearth-openai-api-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "komodo-api-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
  "komodo-api-secret.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
    recipients."wanda"
  ];
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
  "typesafe-api-key.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
  "unifi-password.age".publicKeys = [
    recipients."nixos-desktop"
    recipients."personal-mac"
  ];
}
