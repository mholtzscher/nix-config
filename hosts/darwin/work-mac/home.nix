{ user, ... }:
{
  imports = [
    ../../../modules/home-manager/home.nix
    ../../../modules/home-manager/hosts/work-mac
  ];

  home = {
    username = user;
    homeDirectory = "/Users/${user}";
  };
}
