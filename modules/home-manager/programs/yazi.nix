{ ... }:
{
  programs.yazi = {
    enable = true;
    enableNushellIntegration = false; # yy lives in the writable Nushell config.
    shellWrapperName = "yy";
    settings = {
      mgr = {
        show_hidden = true;
      };
    };
  };
}
