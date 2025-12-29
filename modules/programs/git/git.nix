{ inputs, ... }:
{
  flake.modules.homeManager.git =
    { lib, config, ... }:
    {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "Michael Holtzscher";
            email = config.systemConstants.userEmail;
          };
          column = {
            ui = "auto";
          };
          branch = {
            sort = "-committerdate";
          };
          tag = {
            sort = "version:refname";
          };
          init = {
            defaultBranch = "main";
          };
          diff = {
            algorithm = "histogram";
            colorMoved = "plain";
            mnemonicPrefix = true;
            renames = true;
          };
          push = {
            autoSetupRemote = true;
          };
          fetch = {
            prune = true;
            pruneTags = true;
            all = true;
          };
          rebase = {
            autoSquash = true;
            autoStash = true;
            updateRefs = true;
          };
          pull = {
            rebase = true;
          };
        };
        lfs.enable = true;
      };
    };
}
