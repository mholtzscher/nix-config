{
  pkgs,
  lib,
  isDarwin,
  ...
}:
{
  xdg.configFile."git/config".enable = lib.mkIf isDarwin false;

  programs.git = {
    enable = true;
    settings = {
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
      credential."https://github.com".helper = [
        ""
        "!gh auth git-credential"
      ];
      credential."https://gist.github.com".helper = [
        ""
        "!gh auth git-credential"
      ];
    };
    includes = [
      { path = "~/.config/delta/gitconfig"; }
    ];
    lfs.enable = true;
  };
}
