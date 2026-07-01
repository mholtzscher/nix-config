let
  recipients = import ./recipients.nix;
in
{
  "dummy-env.age".publicKeys = [ recipients."personal-mac" ];
}
