{ isWork, ... }:
{
  programs = {
    atuin = {
      enable = true;
      settings = {
        # Disable sync on work hosts, enable on personal hosts
        auto_sync = !isWork;
        sync_address = if !isWork then "https://atuin.holtzscher.com" else "";
      };
    };
  };
}
