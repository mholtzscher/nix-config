# Jujutsu - Git-compatible VCS (jj)
{
  flake.modules.homeManager.jujutsu = {
    programs.jujutsu = {
      enable = true;
      settings.user = {
        name = "Michael Holtzscher";
        email = "michael@holtzscher.com";
      };
    };
  };
}
