{ ... }:
{
  programs = {
    fzf = {
      enable = true;
      # Atuin owns Ctrl-R for history search in nushell/zsh.
      historyWidget.command = "";
    };
  };
}
