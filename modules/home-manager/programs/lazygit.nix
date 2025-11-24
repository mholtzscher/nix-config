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
        };

        customCommands = [
          {
            key = "O";
            description = "Open Pull Request with GitHub CLI";
            context = "global";
            command = "gh pr create -df && gh pr view --web";
            loadingText = "Creating Pull Request";
          }
          {
            key = "C";
            description = "AI Commit - Generate conventional commit (with confirmation)";
            context = "files";
            command = ''nu --config "$HOME/Library/Application Support/nushell/config.nu" -c 'ai_commit' '';
            output = "terminal";
            loadingText = "Generating commit message with AI...";
          }
          {
            key = "<c-c>";
            description = "AI Commit - Auto-commit without confirmation";
            context = "files";
            command = ''nu --config "$HOME/Library/Application Support/nushell/config.nu" -c 'ai_commit --yes' '';
            output = "terminal";
            loadingText = "Generating and committing with AI...";
          }
        ];
      };
    };
  };
}
