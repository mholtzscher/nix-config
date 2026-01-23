# NixOS module for Brave browser policies
# Writes policies to /etc/brave/policies/managed/ where Brave reads them
{ ... }:
let
  policies = import ../shared/brave-policies.nix;
in
{
  environment.etc."brave/policies/managed/policies.json" = {
    mode = "0644";
    text = builtins.toJSON policies;
  };
}
