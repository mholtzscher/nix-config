# Delta - Beautiful git diff viewer
{
  flake.modules.homeManager.delta = {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        dark = true;
      };
    };
  };
}
