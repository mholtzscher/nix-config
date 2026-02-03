# Git - Distributed version control system
{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;

      # Shared settings across all hosts
      settings = {
        # Default identity (can be overridden per-host)
        user = {
          name = "Michael Holtzscher";
          email = "michael@holtzscher.com";
        };

        column.ui = "auto";
        branch.sort = "-committerdate";
        tag.sort = "version:refname";
        init.defaultBranch = "main";

        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };

        push.autoSetupRemote = true;

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

        pull.rebase = true;
      };

      lfs.enable = true;
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        dark = true;
      };
    };
  };
}
