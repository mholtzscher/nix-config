# Shared nix-darwin base config
{ config, lib, ... }:
let
  cfg = config.myFeatures.darwinBase;
in
{
  options.myFeatures.darwinBase = {
    enable = lib.mkEnableOption "darwin base config" // {
      default = true;
      description = "Shared nix-darwin base settings (stateVersion, unfree, nix-homebrew)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.darwin.base =
      { user, ... }:
      {
        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 5;

        nixpkgs.config.allowUnfree = true;

        nix-homebrew = {
          enable = true;
          enableRosetta = true;
          inherit user;
          autoMigrate = true;
        };
      };
  };
}
