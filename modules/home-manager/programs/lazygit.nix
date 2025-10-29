{ ... }:
{
  programs = {
    lazygit = {
      enable = true;
      settings = {
        commitLength = {
          show = false;
        };

        gui = {
          nerdFontsVersion = "3";
          theme = {
            activeBorderColor = [
              "#ff9e64"
              "bold"
            ];
            inactiveBorderColor = [ "#27a1b9" ];
            searchingActiveBorderColor = [
              "#ff9e64"
              "bold"
            ];
            optionsTextColor = [ "#7aa2f7" ];
            selectedLineBgColor = [ "#283457" ];
            cherryPickedCommitFgColor = [ "#7aa2f7" ];
            cherryPickedCommitBgColor = [ "#bb9af7" ];
            markedBaseCommitFgColor = [ "#7aa2f7" ];
            markedBaseCommitBgColor = [ "#e0af68" ];
            unstagedChangesColor = [ "#db4b4b" ];
            defaultFgColor = [ "#c0caf5" ];
          };
        };

        customCommands = [
          {
            key = "O";
            description = "Open Pull Request with GitHub CLI";
            context = "global";
            command = "gh pr create -df && gh pr view --web";
            loadingText = "Creating Pull Request";
          }
          # {
          #   key = "<c-o>";
          #   description = "Advanced - Open Pull Request with GitHub CLI";
          #   context = "global";
          #   prompts = [
          #     {
          #       type = "input";
          #       title = "Jira Ticket";
          #       key = "JiraTicket";
          #     }
          #   ];
          #   command = "gh pr create -df && gh pr view --web";
          #   loadingText = "Creating Pull Request";
          # }
        ];
      };
    };
  };
}
