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
          # Theme managed by catppuccin
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
