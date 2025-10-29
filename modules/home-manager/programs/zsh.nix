{ ... }:
let
  sharedAliases = import ../shared-aliases.nix;
in
{
  programs = {
    zsh = {
      enable = true;
      shellAliases = sharedAliases.shellAliases // {
      };
      initContent = ''
        if [ -f /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh ]; then
            source /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh
        fi
      '';
      sessionVariables = {
        PATH = "$PATH:/Users/michael/.local/bin";
        FZF_DEFAULT_OPTS = " \
            --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
            --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
            --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
            --color=selected-bg:#45475a \
            --multi";
      };
      antidote = {
        enable = true;
        plugins = [
          "zsh-users/zsh-syntax-highlighting"
          "zsh-users/zsh-completions"
          "zsh-users/zsh-autosuggestions"
          "Aloxaf/fzf-tab"
          "getantidote/use-omz"
          "ohmyzsh/ohmyzsh path:lib"
          "ohmyzsh/ohmyzsh path:plugins/asdf"
          "ohmyzsh/ohmyzsh path:plugins/aws"
          "ohmyzsh/ohmyzsh path:plugins/command-not-found"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/gradle"
          "ohmyzsh/ohmyzsh path:plugins/sudo"
          "ohmyzsh/ohmyzsh path:plugins/terraform"
        ];
      };
    };
  };
}
