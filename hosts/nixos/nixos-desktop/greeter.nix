{
  config,
  user,
  ...
}:
{
  # The greeter discovers sessions through XDG_DATA_DIRS. NixOS keeps display
  # manager sessions in a separate link farm rather than the system profile.
  systemd.services.greetd.environment.XDG_DATA_DIRS =
    "${config.services.displayManager.sessionData.desktops}/share";

  programs.noctalia-greeter = {
    enable = true;
    settings = {
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
