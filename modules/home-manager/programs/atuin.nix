{
  lib,
  ...
}:
{
  programs = {
    atuin = {
      enable = true;
      settings = {
        # Default: enable auto sync and set sync address
        # Work Mac will override these in its host-specific config
        auto_sync = true;
        sync_address = "https://atuin.holtzscher.com";
      };
    };
  };
}
