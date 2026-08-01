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
      settings =
        lib.optionalAttrs (!isWork) {
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
          "*".IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        };
    };
  };
}
