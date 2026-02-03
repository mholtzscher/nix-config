# Yazi - terminal file manager
{
  flake.modules.homeManager.yazi = {
    programs.yazi = {
      enable = true;
      settings.mgr.show_hidden = true;
    };
  };
}
