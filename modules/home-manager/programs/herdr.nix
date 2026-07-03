{ pkgs, ... }:
{
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [theme]
    name = "catppuccin"

    [terminal]
    default_shell = "${pkgs.nushell}/bin/nu"
  '';
}
