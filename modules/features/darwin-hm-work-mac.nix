# nix-darwin home-manager config: work mac
{ config, lib, ... }:
let
  cfg = config.myFeatures.darwinHmWorkMac;
in
{
  options.myFeatures.darwinHmWorkMac = {
    enable = lib.mkEnableOption "darwin home-manager (work mac)" // {
      default = true;
      description = "Work mac home-manager wiring inside nix-darwin";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.darwin.hmWorkMac =
      {
        inputs,
        user,
        self,
        lib,
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
              self.modules.homeManager.profileCommon
              self.modules.homeManager.catppuccinTheme
              self.modules.homeManager.hostWorkMac
            ];

            programs.git.settings.user.email = lib.mkForce "michaelholtzcher@company.com";
          };
        };
      };
  };
}
