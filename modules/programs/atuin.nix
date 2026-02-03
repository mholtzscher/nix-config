# Atuin - shell history with optional sync
{
  flake.modules.homeManager.atuin =
    {
      isWork ? false,
      ...
    }:
    {
      programs.atuin = {
        enable = true;
        settings = {
          auto_sync = !isWork;
          sync_address = if !isWork then "https://atuin.holtzscher.com" else "";
        };
      };
    };
}
