# SSH - client configuration
{ config, lib, ... }:
let
  cfg = config.myFeatures.ssh;
in
{
  options.myFeatures.ssh = {
    enable = lib.mkEnableOption "ssh configuration" // {
      default = true;
      description = "Enable ssh client configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.ssh =
      {
        lib,
        pkgs,
        isWork ? false,
        ...
      }:
      {
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          includes = lib.optionals (!isWork) [ "~/.ssh/1Password/config" ];

          matchBlocks = lib.optionalAttrs (!isWork) {
            mina-nas = {
              hostname = "10.69.69.156";
              user = "root";
            };

            max-nas = {
              hostname = "10.69.69.186";
              user = "root";
            };

            wanda = {
              hostname = "10.69.69.60";
              user = "michael";
            };

            "*" = {
              identityAgent =
                if pkgs.stdenv.isDarwin then
                  "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
                else
                  "~/.1password/agent.sock";
            };
          };
        };
      };
  };
}
