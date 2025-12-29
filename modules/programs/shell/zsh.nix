{ inputs, ... }:
{
  flake.modules.homeManager.zsh =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      sharedAliases = import ./files/_aliases.nix { inherit pkgs; };
      workOnboardingScript = ''
        if [ -f /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh ]; then
            source /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh
        fi
      '';
    in
    {
      programs.zsh = {
        enable = true;
        shellAliases = sharedAliases.shellAliases // { };
        initContent = ''
          ${if config.systemConstants.isWork then workOnboardingScript else ""}

          # Platform-aware Nix build/validate command
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
          nup() {
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
              nixos-rebuild switch --sudo --flake ~/nix-config
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
