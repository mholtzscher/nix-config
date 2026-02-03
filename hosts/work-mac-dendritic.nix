# Work Mac - Host Configuration
# References dendritic modules but defined separately to avoid recursion
{ inputs, ... }:
let
  user = "michaelholtzcher";
  lib = inputs.nixpkgs.lib;
in
inputs.nix-darwin.lib.darwinSystem {
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

    # Dendritic system modules
    inputs.self.modules.darwin.system
    inputs.self.modules.darwin.homebrewCommon
    inputs.self.modules.darwin.homebrewWorkMac
    inputs.self.modules.darwin.hostWorkMac

    # Home-manager configuration with git email override
    {
      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      nixpkgs.config.allowUnfree = true;

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
          home = {
            username = user;
            homeDirectory = "/Users/${user}";
            stateVersion = "24.11";
          };
          programs.home-manager.enable = true;
          imports = [
            inputs.self.modules.homeManager.profileCommon

            # Theme (enable explicitly on macOS)
            inputs.self.modules.homeManager.catppuccinTheme

            # Host-specific config
            inputs.self.modules.homeManager.hostWorkMac
          ];

          # Override git email for work context
          programs.git.settings.user.email = lib.mkForce "michaelholtzcher@company.com";
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

  ];
}
