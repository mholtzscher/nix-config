# nix-darwin host-specific config: work mac
{ config, lib, ... }:
let
  cfg = config.myFeatures.darwinHostWorkMac;
in
{
  options.myFeatures.darwinHostWorkMac = {
    enable = lib.mkEnableOption "darwin host config (work mac)" // {
      default = true;
      description = "Host-specific nix-darwin settings for work mac";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.darwin.hostWorkMac =
      { user, ... }:
      {
        users.users.${user} = {
          name = user;
          home = "/Users/${user}";
        };

        system.primaryUser = user;

        system.defaults.dock.persistent-apps = [
          "/Applications/Arc.app"
          "/System/Applications/Messages.app"
          "/Applications/Slack.app"
          "/Applications/Ghostty.app"
          "/Applications/Postico.app"
          "/Applications/IntelliJ IDEA.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/Applications/Todoist.app"
          "/System/Applications/Music.app"
          "/Users/${user}/Applications/Google Gemini.app"
          "/Users/${user}/Applications/Reclaim.app"
        ];
      };
  };
}
