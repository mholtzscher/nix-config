# nix-darwin host-specific config: personal mac
{
  flake.modules.darwin.hostPersonalMac =
    { user, ... }:
    {
      users.users.${user} = {
        name = user;
        home = "/Users/${user}";
        uid = 501;
      };

      system.primaryUser = user;

      system.defaults.dock.persistent-apps = [
        "/Applications/Arc.app"
        "/System/Applications/Messages.app"
        "/Applications/WhatsApp.app"
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
}
