{ pkgs, ... }:
{
  programs = {
    fzf = {
      enable = true;
      # Patch fzf's generated Nushell integration until upstream replaces the command deprecated in Nushell 0.114.
      package = pkgs.fzf.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace shell/completion.nu \
            --replace-fail "str downcase" "str lowercase"
        '';
      });
      # Atuin owns Ctrl-R for history search in nushell/zsh.
      historyWidget.command = "";
    };
  };
}
