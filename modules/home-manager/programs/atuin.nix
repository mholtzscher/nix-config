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
      # Nushell integration is sourced manually in nushell.nix (it patches
      # the ctrl+r keybind name), so disable home-manager's default here.
      # Personal-host zsh integration is guarded in-shell so a cleared
      # runtime directory does not break the first shell after reboot.
      enableNushellIntegration = false;
      enableZshIntegration = isWork;
      settings = {
        # Disable sync on work hosts, enable on personal hosts
        auto_sync = !isWork;
      }
      // lib.optionalAttrs (!isWork) {
        sync_address = "https://atuin.holtzscher.com";
        key_path = config.age.secrets.atuin-key.path;
      };
    };
  };
}
