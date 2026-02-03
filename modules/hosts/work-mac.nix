# Work Mac - Dendritic Host Configuration
# Overrides git email in the home-manager config
{
  config,
  lib,
  inputs,
  ...
}:
let
  user = "michaelholtzcher";
in
{
  flake.darwinConfigurations."Michael-Holtzscher-Work" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {
      inherit inputs user;
      self = inputs.self;
      isWork = true;
    };
    modules = [
      # Import home-manager module
      inputs.home-manager.darwinModules.home-manager

      # Import nix-homebrew module
      inputs.nix-homebrew.darwinModules.nix-homebrew

      # Home-manager configuration with git email override
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs user;
            self = inputs.self;
            isWork = true;
            isDarwin = true;
            isLinux = false;
            currentSystemName = "work-mac";
            currentSystemUser = user;
          };
          users.${user} = {
            imports = [
              # Core CLI tools
              inputs.self.modules.homeManager.bat
              inputs.self.modules.homeManager.eza
              inputs.self.modules.homeManager.fzf
              inputs.self.modules.homeManager.ripgrep
              inputs.self.modules.homeManager.zoxide
              inputs.self.modules.homeManager.fd

              # Git with work email override
              inputs.self.modules.homeManager.git

              # Catppuccin theming
              inputs.catppuccin.homeModules.catppuccin
            ];

            # Override git email for work context
            programs.git.userEmail = lib.mkForce "michaelholtzcher@company.com";
          };
        };

        # nix-homebrew configuration
        nix-homebrew = {
          enable = true;
          enableRosetta = true;
          inherit user;
          autoMigrate = true;
        };
      }

      # Legacy bridge
      ../../hosts/darwin/work-mac.nix
    ];
  };
}
