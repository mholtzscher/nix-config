{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = lib.optionals (config.home.username == "michael") [
        "~/.ssh/1Password/config"
      ];
      matchBlocks = {
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
            if config.home.username == "michael" then
              if pkgs.stdenv.isDarwin then
                "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
              else
                "~/.1password/agent.sock"
            else
              null;
        };
      };
    };
  };
}
