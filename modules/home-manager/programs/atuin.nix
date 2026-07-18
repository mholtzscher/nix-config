{
  config,
  lib,
  isWork,
  ...
}:
{
  programs = {
    atuin = {
      enable = true;
      # Personal-host integrations are guarded in each shell so a cleared
      # runtime directory does not break the first shell after reboot.
      enableNushellIntegration = isWork;
      enableZshIntegration = isWork;
      settings = {
        # Disable sync on work hosts, enable on personal hosts
        auto_sync = !isWork;
        sync_address = if !isWork then "https://atuin.holtzscher.com" else "";
      }
      // lib.optionalAttrs (!isWork) {
        key_path = config.age.secrets.atuin-key.path;
      };
    };
  };
}
