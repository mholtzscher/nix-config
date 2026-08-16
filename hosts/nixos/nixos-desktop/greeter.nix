{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  mkNiriShellSession =
    {
      id,
      name,
      shell,
    }:
    let
      launcher = pkgs.writeShellScript "${id}-session" ''
        export NIRI_SHELL=${lib.escapeShellArg shell}
        exec ${config.programs.niri.package}/bin/niri-session
      '';
      desktopFile = pkgs.writeText "${id}.desktop" ''
        [Desktop Entry]
        Name=${name}
        Comment=Niri with ${name}
        Exec=${launcher}
        Type=Application
        DesktopNames=niri
      '';
    in
    pkgs.runCommand "${id}-wayland-session"
      {
        passthru.providedSessions = [ id ];
      }
      ''
        mkdir -p $out/share/wayland-sessions
        ln -s ${desktopFile} $out/share/wayland-sessions/${id}.desktop
      '';

  dmsSession = mkNiriShellSession {
    id = "niri-dms";
    name = "Niri + DMS";
    shell = "dms";
  };

  noctaliaSession = mkNiriShellSession {
    id = "niri-noctalia";
    name = "Niri + Noctalia";
    shell = "noctalia";
  };
in
{
  # Replace Niri's generic session with shell-specific choices. niri-session
  # imports NIRI_SHELL into the user systemd manager before starting Niri.
  services.displayManager = {
    defaultSession = "niri-dms";
    sessionPackages = lib.mkForce [
      dmsSession
      noctaliaSession
    ];
  };

  # The greeter discovers sessions through XDG_DATA_DIRS. NixOS keeps display
  # manager sessions in a separate link farm rather than the system profile.
  systemd.services.greetd.environment.XDG_DATA_DIRS =
    "${config.services.displayManager.sessionData.desktops}/share";

  programs.noctalia-greeter = {
    enable = true;
    settings = {
      # Leave the session unset so the greeter remembers the last selection.
      user.default = user;

      output = {
        width = 5120;
        height = 1440;
        scale = 1;
      };

      idle.timeout = 0;
      keyboard.layout = "us";
    };
  };
}
