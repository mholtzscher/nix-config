# NixOS Desktop home-manager wiring module
{
  flake.modules.nixos.desktopHm =
    {
      inputs,
      user,
      self,
      ...
    }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inherit inputs user;
          self = self;
          isWork = false;
          isDarwin = false;
          isLinux = true;
          currentSystemName = "nixos-desktop";
          currentSystemUser = user;
        };

        users.${user} = {
          home.stateVersion = "24.11";
          programs.home-manager.enable = true;
          imports = [
            # Common profile (CLI tools, shell, etc.)
            self.modules.homeManager.profileCommon
            self.modules.homeManager.catppuccinTheme
            self.modules.homeManager.ollama

            # Host-specific user config
            self.modules.homeManager.hostNixosDesktop

            # Browsers
            self.modules.homeManager.firefox
            self.modules.homeManager.zen
            self.modules.homeManager.webapps # Web apps module (defines programs.webapps option)

            # Desktop environment
            self.modules.homeManager.nixosComposition # Niri settings
            self.modules.homeManager.nixosGaming # Gaming packages + MangoHud
            self.modules.homeManager.nixosWallpaper # Awww wallpaper daemon
          ];
        };
      };
    };
}
