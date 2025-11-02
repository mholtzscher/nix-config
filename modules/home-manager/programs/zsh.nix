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

        # Platform-aware Nix build/validate command
        # On macOS: darwin-rebuild build
        # On Linux: nix flake check
        nb() {
          if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            nix flake check --flake ~/nix-config
          elif [[ "$OSTYPE" == "darwin"* ]]; then
            darwin-rebuild build --flake ~/.config/nix-config
          else
            echo "Unsupported OS: $OSTYPE"
            return 1
          fi
        }

        # Platform-aware Nix apply/switch command
        # On macOS: sudo darwin-rebuild switch
        # On Linux: sudo nixos-rebuild switch --flake ~/.config/nix-config#desktop
        nup() {
          if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            nixos-rebuild switch --sudo --flake ~/.config/nix-config#desktop
          elif [[ "$OSTYPE" == "darwin"* ]]; then
            sudo darwin-rebuild switch --flake ~/.config/nix-config
          else
            echo "Unsupported OS: $OSTYPE"
            return 1
          fi
        }
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
