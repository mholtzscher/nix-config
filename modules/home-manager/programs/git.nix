{
  pkgs,
  lib,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      # Delta is installed by Mise; its writable settings are synced separately.
      pager = {
        blame = "delta";
        diff = "delta";
        log = "delta";
        show = "delta";
      };
      interactive.diffFilter = "delta --color-only";
      user = {
        name = "Michael Holtzscher";
        email = lib.mkDefault "michael@holtzscher.com";
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
        # followTags = true;
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
    includes = [ { path = "~/.config/delta/config.gitconfig"; } ];
  };
}
