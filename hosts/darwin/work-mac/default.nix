{
  inputs,
  user,
  ...
}:
{
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

  system.primaryUser = user;
}
