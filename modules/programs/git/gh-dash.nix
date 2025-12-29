{ inputs, ... }:
{
  flake.modules.homeManager.gh-dash =
    { pkgs, ... }:
    let
      nuConfig =
        if pkgs.stdenv.isDarwin then
          "$HOME/Library/Application Support/nushell/config.nu"
        else
          "$HOME/.config/nushell/config.nu";
    in
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
              filters = "repo:paytient/m3p state:open";
              title = "M3P Open";
            }
            {
              title = "Legends Review Requested";
              filters = "is:open org:paytient team-review-requested:paytient/legends-of-the-ledger";
            }
            {
              title = "Review Requested";
              filters = "is:open review-requested:@me";
            }
            {
              filters = "repo:paytient/m3p";
              title = "M3P All";
              limit = 20;
            }
            {
              filters = "is:open owner:mholtzscher";
              title = "mholtzscher";
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
