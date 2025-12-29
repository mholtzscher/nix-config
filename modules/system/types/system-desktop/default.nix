{ inputs, ... }:
{
  # System Desktop - inherits from system-cli, adds desktop environment
  # Used by graphical hosts only (nixos-desktop, darwin macs)

  flake.modules.nixos.system-desktop = {
    imports = with inputs.self.modules.nixos; [
      system-cli
      niri
      vicinae
      _1password
    ];
  };

  flake.modules.darwin.system-desktop = {
    imports = with inputs.self.modules.darwin; [
      system-cli
      aerospace
      _1password
    ];
  };

  # Home-manager desktop - imports all desktop programs directly
  flake.modules.homeManager.system-desktop = {
    imports = [
      ../../system/types/system-default/homeManager.nix
      ../../programs/browser/firefox.nix
      ../../desktop/waybar/default.nix
      ../../desktop/webapps/default.nix
    ];
  };
}
