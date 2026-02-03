# Shared nix-darwin base config
{
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
}
