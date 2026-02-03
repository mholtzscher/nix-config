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
            # Core CLI tools - from dendritic modules
            inputs.self.modules.homeManager.bat
            inputs.self.modules.homeManager.eza
            inputs.self.modules.homeManager.fzf
            inputs.self.modules.homeManager.ripgrep
            inputs.self.modules.homeManager.zoxide
            inputs.self.modules.homeManager.fd

            # Git - from dendritic modules (with work email override)
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

    # Legacy system config only (no home-manager bridge to avoid duplicates)
    {
      imports = [
        ../modules-legacy/homebrew/hosts/work-mac.nix
      ];

      users.users.${user} = {
        name = user;
        home = "/Users/${user}";
      };

      system = {
        primaryUser = user;
        defaults = {
          dock = {
            persistent-apps = [
              "/Applications/Arc.app"
              "/System/Applications/Messages.app"
              "/Applications/Slack.app"
              "/Applications/Ghostty.app"
              "/Applications/Postico.app"
              "/Applications/IntelliJ IDEA.app"
              "/System/Applications/Mail.app"
              "/System/Applications/Calendar.app"
              "/Applications/Todoist.app"
              "/System/Applications/Music.app"
              "/Users/michaelholtzcher/Applications/Google Gemini.app"
              "/Users/michaelholtzcher/Applications/Reclaim.app"
            ];
          };
        };
      };
    }
  ];
}
