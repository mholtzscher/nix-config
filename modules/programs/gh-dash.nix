# gh-dash - dashboard for GitHub PRs/issues
{
  flake.modules.homeManager.gh-dash =
    {
      lib,
      isWork ? false,
      ...
    }:
    {
      programs.gh-dash = {
        enable = true;
        settings = {
          prSections = [
            {
              title = "My Pull Requests";
              filters = "is:open author:@me";
            }
            {
              title = "Review Requested";
              filters = "is:open review-requested:@me";
            }
            {
              filters = "is:open owner:mholtzscher";
              title = "mholtzscher";
              limit = 20;
            }
          ]
          ++ lib.optionals isWork [
            {
              filters = "repo:paytient/m3p state:open";
              title = "M3P Open";
            }
            {
              title = "Legends Review Requested";
              filters = "is:open org:paytient team-review-requested:paytient/legends-of-the-ledger";
            }
            {
              filters = "repo:paytient/m3p";
              title = "M3P All";
              limit = 20;
            }
          ];

          pager.diff = "delta";

          defaults.preview.open = true;

          repoPaths = lib.optionalAttrs isWork {
            "paytient/m3p" = "~/code/m3p";
          };

          smartFilteringAtLaunch = false;

          keybindings = lib.optionalAttrs isWork {
            prs = [
              {
                name = "Octo";
                key = "O";
                command = "zellij run --name '{{.RepoName}} PR#{{.PrNumber}}' --cwd {{.RepoPath}} -- nvim -c ':silent Octo pr edit {{.PrNumber}}'";
              }
            ];
          };
        };
      };
    };
}
