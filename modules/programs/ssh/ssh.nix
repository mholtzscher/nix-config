{ inputs, ... }:
{
  flake.modules.homeManager.ssh =
    { pkgs, lib, config, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = lib.optionals (!config.systemConstants.isWork) [
          "~/.ssh/1Password/config"
        ];
        matchBlocks = lib.optionalAttrs (!config.systemConstants.isWork) {
          mina-nas = {
            hostname = "10.69.69.156";
            user = "root";
          };
        };
      };

      home.file.".config/1Password/ssh/agent.toml".source = ./files/1password-agent.toml;
    };
}
