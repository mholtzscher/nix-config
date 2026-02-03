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
          isDarwin = true;
          isLinux = false;
          currentSystemName = "personal-mac";
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

            # Git - from dendritic modules (uses default email)
            inputs.self.modules.homeManager.git

            # Catppuccin theming
            inputs.catppuccin.homeModules.catppuccin
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

    # Legacy system config (dock, system settings, homebrew)
    # Note: We don't import the legacy home-manager modules since we use dendritic
    {
      # Import just the system-level parts from legacy config
      imports = [
        ../modules-legacy/homebrew/hosts/personal-mac.nix
      ];

      users.users.${user} = {
        name = user;
        home = "/Users/${user}";
        uid = 501;
      };

      system = {
        primaryUser = user;
        defaults = {
          dock = {
            persistent-apps = [
              "/Applications/Arc.app"
              "/System/Applications/Messages.app"
              "/Applications/WhatsApp.app"
              "/Applications/1Password.app"
              "/Applications/Ghostty.app"
              "/Applications/IntelliJ IDEA CE.app"
              "/System/Applications/Mail.app"
              "/System/Applications/Calendar.app"
              "/Applications/Todoist.app"
              "/System/Applications/Music.app"
              "/System/Applications/News.app"
            ];
          };
        };
      };
    }
  ];
}
