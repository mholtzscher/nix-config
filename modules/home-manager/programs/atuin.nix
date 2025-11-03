{
  config,
  lib,
  ...
}:
let
  hostname = config.networking.hostName or "";
  isWorkMachine = lib.hasInfix "Work" hostname;
in
{
  programs = {
    atuin = {
      enable = true;
      settings = {
        # Disable auto sync on work Mac
        auto_sync = !isWorkMachine;
      }
      // lib.optionalAttrs (!isWorkMachine) {
        # Set sync_address on all machines except work Mac
        sync_address = "https://atuin.holtzscher.com";
      };
    };
  };
}
