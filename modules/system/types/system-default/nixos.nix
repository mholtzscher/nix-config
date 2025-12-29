{ inputs, ... }:
{
  flake.modules.nixos.system-default = {
    imports = with inputs.self.modules; [
      generic.constants
      generic.nix-settings
      nixos.catppuccin
      nixos.home-manager
    ];

    # Enable zsh shell system-wide
    programs.zsh.enable = true;
  };
}
