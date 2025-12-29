{ inputs, ... }:
{
  # Catppuccin theming for NixOS system-level components

  flake.modules.nixos.catppuccin = {
    imports = [
      inputs.catppuccin.nixosModules.catppuccin
    ];

    catppuccin = {
      enable = true;
      flavor = "mocha";
    };
  };

  # Darwin catppuccin (if needed at system level)
  flake.modules.darwin.catppuccin = {
    # Darwin doesn't have system-level catppuccin, handled in home-manager
  };
}
