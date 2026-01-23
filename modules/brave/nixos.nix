# Brave browser - NixOS module
# Manages system-level policies via /etc/brave/policies/managed/
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.brave;
  defaultPolicies = import ./default.nix;
in
{
  options.programs.brave = {
    enable = lib.mkEnableOption "Brave browser policies";

    policies = lib.mkOption {
      type = lib.types.attrs;
      default = defaultPolicies;
      description = ''
        Brave browser policies written to /etc/brave/policies/managed/.
        See https://chromeenterprise.google/policies/ for available options.
      '';
      example = lib.literalExpression ''
        {
          BraveRewardsDisabled = true;
          PasswordManagerEnabled = false;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."brave/policies/managed/policies.json" = {
      text = builtins.toJSON cfg.policies;
      mode = "0644";
    };
  };
}
