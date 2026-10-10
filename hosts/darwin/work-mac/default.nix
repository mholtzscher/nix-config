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
        imports = [ ./home.nix ];
        _module.args.user = user;
      };
  };

  system.primaryUser = user;
}
