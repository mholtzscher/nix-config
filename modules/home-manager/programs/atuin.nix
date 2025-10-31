{
  config,
  lib,
  ...
}:
{
  programs = {
    atuin = {
      enable = true;
      settings = {
        # Disable auto sync on work Mac (user: michaelholtzcher)
        # TODO: make this work on nixos desktop
        auto_sync = config.home.username == "michael";
      }
      // lib.optionalAttrs (config.home.username == "michael") {
        # Only set sync_address on personal Mac (user: michael)
        sync_address = "https://atuin.holtzscher.com";
      };
    };
  };
}
