{ inputs, ... }:
{
  flake.modules.homeManager.atuin =
    { config, ... }:
    {
      programs.atuin = {
        enable = true;
        settings = {
          auto_sync = !config.systemConstants.isWork;
          sync_address = if !config.systemConstants.isWork then "https://atuin.holtzscher.com" else "";
        };
      };
    };
}
