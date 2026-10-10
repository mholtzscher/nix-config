{ user, ... }:
{
  imports = [
    ../../../modules/home-manager/home.nix
    ../../../modules/home-manager/hosts/personal-mac
  ];

  home = {
    username = user;
    homeDirectory = "/Users/${user}";
  };
}
