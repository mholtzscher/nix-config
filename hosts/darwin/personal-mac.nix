{
  pkgs,
  inputs,
  user,
  ...
}:
{
  imports = [
    ../../modules/homebrew/hosts/personal-mac.nix
  ];

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    uid = 501;
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
          ../../modules/home-manager/home.nix
          ../../modules/home-manager/hosts/personal-mac.nix
        ];
      };
  };

  nix-homebrew = {
    enable = true;
    # Apple Silicon Only
    enableRosetta = true;
    # User owning the Homebrew prefix
    inherit user;

    autoMigrate = true;
  };

  system = {
    primaryUser = user;
    defaults = {
      dock = {
        persistent-apps = [
          "/Applications/Arc.app"
          "/Applications/Obsidian.app"
          "/System/Applications/Messages.app"
          "/Applications/WhatsApp.app"
          "${pkgs.discord}/Applications/Discord.app"
          "/Applications/1Password.app"
          "/Applications/Ghostty.app"
          "/Applications/IntelliJ IDEA CE.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/Applications/Todoist.app"
          "/System/Applications/Music.app"
          "/System/Applications/News.app"
        ];
      };

    };
  };

}
