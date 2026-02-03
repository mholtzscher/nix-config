# NixOS Desktop - Host Configuration
# References dendritic modules but defined separately to avoid recursion
{ inputs, ... }:
let
  user = "michael";
  system = "x86_64-linux";
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs user;
    self = inputs.self;
    isWork = false;
  };
  modules = [
    # Import home-manager NixOS module
    inputs.home-manager.nixosModules.home-manager

    # Import catppuccin
    inputs.catppuccin.nixosModules.catppuccin

    # Import Niri
    inputs.niri.nixosModules.niri

    # Import DMS
    inputs.dms.nixosModules.default
    inputs.dms.nixosModules.greeter

    # Home-manager configuration
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inherit inputs user;
          self = inputs.self;
          isWork = false;
          isDarwin = false;
          isLinux = true;
          currentSystemName = "nixos-desktop";
          currentSystemUser = user;
        };
        users.${user} = {
          imports = [
            # Core CLI tools - from dendritic modules
            inputs.self.modules.homeManager.bat
            inputs.self.modules.homeManager.eza
            inputs.self.modules.homeManager.fzf
            inputs.self.modules.homeManager.ripgrep
            inputs.self.modules.homeManager.zoxide
            inputs.self.modules.homeManager.fd

            # Development tools - from dendritic modules
            inputs.self.modules.homeManager.git

            # Catppuccin theming
            inputs.catppuccin.homeModules.catppuccin
          ];
        };
      };
    }

  ];
}
