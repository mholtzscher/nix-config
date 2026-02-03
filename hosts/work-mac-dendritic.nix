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
      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

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
            # Core CLI tools - from dendritic modules
            inputs.self.modules.homeManager.bat
            inputs.self.modules.homeManager.eza
            inputs.self.modules.homeManager.fzf
            inputs.self.modules.homeManager.ripgrep
            inputs.self.modules.homeManager.zoxide
            inputs.self.modules.homeManager.fd

            # Shell + prompt + env
            inputs.self.modules.homeManager.zsh
            inputs.self.modules.homeManager.starship
            inputs.self.modules.homeManager.direnv
            inputs.self.modules.homeManager.atuin

            # SSH
            inputs.self.modules.homeManager.ssh

            # Git - from dendritic modules (with work email override)
            inputs.self.modules.homeManager.git

            # GitHub + JSON + monitoring
            inputs.self.modules.homeManager.gh
            inputs.self.modules.homeManager.gh-dash
            inputs.self.modules.homeManager.jq
            inputs.self.modules.homeManager.btop

            # Tooling
            inputs.self.modules.homeManager.mise
            inputs.self.modules.homeManager.carapace
            inputs.self.modules.homeManager.k9s
            inputs.self.modules.homeManager.lazydocker
            inputs.self.modules.homeManager.lazygit

            # JS runtime
            inputs.self.modules.homeManager.bun

            # Catppuccin theming
            inputs.catppuccin.homeModules.catppuccin
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
