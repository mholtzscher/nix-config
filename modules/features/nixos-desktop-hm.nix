# NixOS Desktop home-manager wiring module
{ config, lib, ... }:
let
  cfg = config.myFeatures.nixosDesktopHm;
in
{
  options.myFeatures.nixosDesktopHm = {
    enable = lib.mkEnableOption "NixOS Desktop HM wiring" // {
      default = true;
      description = "NixOS Desktop home-manager configuration wiring";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "michael";
      description = "Primary user for NixOS Desktop";
    };
  };

  config = lib.mkIf cfg.enable {
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
              self.modules.homeManager.profileCommon
              self.modules.homeManager.hostNixosDesktop
              self.modules.homeManager.firefox
              self.modules.homeManager.zen
              self.modules.homeManager.webapps
            ];
          };
        };
      };
  };
}
