{
  lib,
  isWork,
  isDarwin,
  ...
}:
let
  onePasswordAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
in
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
          IdentityAgent = "none";
        };
      }
      // lib.optionalAttrs (!isWork) {
        mina-nas = {
          HostName = "10.69.69.156";
          User = "root";
        };

        max-nas = {
          HostName = "10.69.69.186";
          User = "root";
        };

        wanda = {
          HostName = "10.69.69.60";
          User = "michael";
        };

        nixos-desktop = {
          HostName = "10.69.69.183";
          User = "michael";
          ForwardAgent = true;
        };
      }
      // lib.optionalAttrs (!isWork && isDarwin) {
        mina-nas.IdentityAgent = onePasswordAgent;
        max-nas.IdentityAgent = onePasswordAgent;
        wanda.IdentityAgent = onePasswordAgent;
        nixos-desktop.IdentityAgent = onePasswordAgent;
      }
      // lib.optionalAttrs (!isWork && !isDarwin) {
        # Preserve a forwarded agent when connected from another machine.
        "Match host mina-nas,max-nas,wanda,nixos-desktop exec \"sh -c 'test -z \\\"$SSH_CONNECTION\\\"'\"".IdentityAgent =
          "~/.1password/agent.sock";
      };
    };
  };
}
