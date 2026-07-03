{
  lib,
  isWork,
  isDarwin,
  ...
}:
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = lib.optionalAttrs (!isWork) {
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
          HostName = "nixos-desktop";
          User = "michael";
          ForwardAgent = true;
        };

        "*" = {
          IdentityAgent =
            if isDarwin then
              "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
            else
              "~/.1password/agent.sock";
        };

        forwarded-agent = lib.hm.dag.entryBefore [ "*" ] {
          header = ''Match exec "test -n \"$SSH_CONNECTION\" -a -n \"$SSH_AUTH_SOCK\""'';
          IdentityAgent = "SSH_AUTH_SOCK";
        };
      };
    };
  };
}
