{
  inputs,
  user,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/homebrew/hosts/work-mac.nix
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
          ../../modules/home-manager/home.nix
          ../../modules/home-manager/hosts/work-mac.nix
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
          "${pkgs.brave}/Applications/Brave.app"
          "/System/Applications/Messages.app"
          "/Applications/Slack.app"
          "/Applications/Ghostty.app"
          "/Applications/Postico.app"
          "/Applications/IntelliJ IDEA.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/Applications/Todoist.app"
          "/System/Applications/Music.app"
          "/Users/michaelholtzcher/Applications/Google Gemini.app"
          "/Users/michaelholtzcher/Applications/Reclaim.app"
        ];
      };
    };
  };
}
