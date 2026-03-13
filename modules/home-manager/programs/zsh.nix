{
  pkgs,
  lib,
  isDarwin,
  isWork,
  ...
}:
let
  sharedAliases = import ../shared-aliases.nix { inherit isWork; };
  workOnboardingScript = ''
    if [ -f /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh ]; then
        source /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh
    fi
  '';
in
{
  programs = {
    zsh = {
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

        # Build with timing visualization using nix-output-monitor (nom)
        # Shows per-derivation build times and progress
        nbt() {
          if ! command -v nom &> /dev/null; then
            echo "nix-output-monitor (nom) not installed. Run nb instead."
            return 1
          fi

          if [[ "$OSTYPE" == "darwin"* ]]; then
            darwin-rebuild build --flake ~/.config/nix-config |& nom
          else
            echo "nom build not supported on this platform"
            return 1
          fi
        }

        # Switch with timing visualization using nix-output-monitor (nom)
        # Shows per-derivation build times and progress during switch
        nupt() {
          if ! command -v nom &> /dev/null; then
            echo "nix-output-monitor (nom) not installed. Run nup instead."
            return 1
          fi

          # Pre-authenticate sudo so password prompt works
          sudo -v

          if [[ "$OSTYPE" == "darwin"* ]]; then
            sudo darwin-rebuild switch --flake ~/.config/nix-config |& nom
          elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo nixos-rebuild switch --flake ~/nix-config |& nom
          else
            echo "nom not yet supported for this platform's switch type"
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

        # Switch with timing visualization using nix-output-monitor (nom)
        # Shows per-derivation build times and progress during switch
        nupt() {
          if ! command -v nom &> /dev/null; then
            echo "nix-output-monitor (nom) not installed. Run nup instead."
            return 1
          fi

          # Pre-authenticate sudo so password prompt works
          sudo -v

          if [[ "$OSTYPE" == "darwin"* ]]; then
            sudo darwin-rebuild switch --flake ~/.config/nix-config 2>&1 | nom
          elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo nixos-rebuild switch --flake ~/nix-config 2>&1 | nom
          else
            echo "nom not yet supported for this platform's switch type"
            return 1
          fi
        }
      '';
      sessionVariables = {
        PATH = "$PATH:/Users/michael/.local/bin";
      };
    };
  };
}
