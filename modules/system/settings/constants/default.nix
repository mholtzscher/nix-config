{ lib, ... }:
{
  # Generic module - usable in all contexts (NixOS, Darwin, Home-Manager)
  flake.modules.generic.constants =
    { lib, ... }:
    {
      options.systemConstants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
        description = "System-wide constants (isWork, userName, etc.)";
      };

      config.systemConstants = {
        isWork = lib.mkDefault false;
        userName = lib.mkDefault "michael";
        userEmail = lib.mkDefault "michael@holtzscher.com";
      };
    };
}
