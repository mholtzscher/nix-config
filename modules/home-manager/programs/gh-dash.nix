{ ... }:
{
  programs = {
    gh-dash = {
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
            title = "Owner";
            limit = 20;
          }
        ];

        pager = {
          diff = "delta";
        };

        defaults = {
          preview = {
            open = true;
          };
        };

        repoPaths = {
          "paytient/m3p" = "~/code/m3p";
        };

        smartFilteringAtLaunch = false;

        keybindings = {
          # prs = [
          #   {
          #     name = "Octo";
          #     key = "O";
          #     command = "zellij run --name '{{.RepoName}} PR#{{.PrNumber}}' --cwd {{.RepoPath}} -- nvim -c ':silent Octo pr edit {{.PrNumber}}'";
          #   }
          # ];
        };

      };
    };
  };
}
