{ inputs, ... }:
{
  flake.modules.darwin.system-default = {
    imports = with inputs.self.modules; [
      generic.constants
      generic.nix-settings
      darwin.home-manager
      darwin.catppuccin
      darwin.homebrew
    ];

    # System state version
    system.stateVersion = 5;
  };
}
