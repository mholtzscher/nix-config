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
      includes = lib.optionals (!isWork) [
        "~/.ssh/1Password/config"
      ];
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
            if isDarwin then
              "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
            else
              "~/.1password/agent.sock";
        };
      };
    };
  };
}
