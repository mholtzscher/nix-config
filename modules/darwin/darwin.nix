{ pkgs, config, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Darwin-specific nix settings
  # Garbage collection schedule for macOS (runs weekly on Sundays at 2:00 AM)
  nix.gc.interval = {
    Weekday = 0; # Sunday
    Hour = 2;
    Minute = 0;
  };

  # Use macOS /bin/zsh; Mise owns interactive shell configuration.
  programs.zsh.enable = false;

  # Keep Nix profiles available without installing Nix Zsh or its global rc files.
  environment.etc."zshenv".text = ''
    if [[ -o rcs && -z ''${__NIX_DARWIN_SET_ENVIRONMENT_DONE-} ]]; then
      . ${config.system.build.setEnvironment}
    fi

    if [[ -r /etc/zshenv.local ]]; then
      source /etc/zshenv.local
    fi
  '';

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # User desktop/app preferences are managed by Mise bootstrap.
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
