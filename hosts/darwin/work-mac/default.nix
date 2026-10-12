{
  inputs,
  user,
  ...
}:
{
  imports = [
    ../../../modules/darwin/homebrew/hosts/work-mac.nix
  ];

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    # uid = 501;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${user} =
      { ... }:
      {
        imports = [
          ../../../modules/home-manager/home.nix
          ../../../modules/home-manager/hosts/work-mac
        ];
      };
  };

  nix-homebrew = {
    enable = true;
    # Apple Silicon Only
    # enableRosetta = true;
    # User owning the Homebrew prefix
    inherit user;

    autoMigrate = true;
  };

  system.primaryUser = user;
}
