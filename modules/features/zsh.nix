# Zsh - shell config and helper functions
{ config, lib, ... }:
let
  cfg = config.myFeatures.zsh;
in
{
  options.myFeatures.zsh = {
    enable = lib.mkEnableOption "zsh configuration" // {
      default = true;
      description = "Enable zsh configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.zsh =
      {
        pkgs,
        isWork ? false,
        ...
      }:
      let
        sharedAliases = import ../../modules-legacy/home-manager/shared-aliases.nix { inherit pkgs; };
        workOnboardingScript = ''
          if [ -f /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh ]; then
              source /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh
          fi
        '';
      in
      {
        home.sessionPath = [
          "$HOME/.local/bin"
        ];

        programs.zsh = {
          enable = true;
          shellAliases = sharedAliases.shellAliases;
          initContent = ''
            ${if isWork then workOnboardingScript else ""}

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
            # On Linux: sudo nixos-rebuild switch --flake ~/nix-config
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
        };
      };
  };
}
