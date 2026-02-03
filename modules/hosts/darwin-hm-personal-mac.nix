# nix-darwin home-manager config: personal mac
{
  flake.modules.darwin.hmPersonalMac =
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
            self.modules.homeManager.profileCommon
            self.modules.homeManager.catppuccinTheme
            self.modules.homeManager.ollama
            self.modules.homeManager.hostPersonalMac
          ];
        };
      };
    };
}
