let
  # Decrypt with ~/.ssh/id_ed25519_agenix_personal-mac on personal-mac.
  personalMac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILk68fR1XZ8WKMgq/1iPem1xfSHY3kM4x2lVdLSSQsPf agenix@personal-mac";
in
{
  "dummy-env.age".publicKeys = [ personalMac ];
}
