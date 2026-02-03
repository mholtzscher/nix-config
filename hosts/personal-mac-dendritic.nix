# Personal Mac (M1 Max) - Host Configuration
# References dendritic modules but defined separately to avoid recursion
{ inputs, ... }:
let
  user = "michael";
in
inputs.nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = {
    inherit inputs user;
    self = inputs.self;
    isWork = false;
  };
  modules = [
    # Import home-manager module
    inputs.home-manager.darwinModules.home-manager

    # Import nix-homebrew module
    inputs.nix-homebrew.darwinModules.nix-homebrew

    # Dendritic system modules
    inputs.self.modules.darwin.system
    inputs.self.modules.darwin.homebrewCommon
    inputs.self.modules.darwin.homebrewPersonalMac
    inputs.self.modules.darwin.hostPersonalMac

    # Home-manager configuration
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
          isWork = false;
          isDarwin = true;
          isLinux = false;
          currentSystemName = "personal-mac";
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
            inputs.self.modules.homeManager.hostPersonalMac
          ];
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
