{ pkgs, config, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Native Mise packages link commands into the standard Homebrew prefix.
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  # Darwin-specific nix settings
  # Garbage collection schedule for macOS (runs weekly on Sundays at 2:00 AM)
  nix.gc.interval = {
    Weekday = 0; # Sunday
    Hour = 2;
    Minute = 0;
  };

  fonts.packages = [
    pkgs.nerd-fonts.iosevka
    pkgs.nerd-fonts.jetbrains-mono
  ];

  programs.zsh.enable = true; # default shell on catalina

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # User preferences are declared in Mise. Guest login is a system-wide
  # policy, which Mise's user-defaults declarations cannot represent.
  system.defaults.loginwindow.GuestEnabled = false;

  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = [ "/Applications" ];
      };
    in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

}
