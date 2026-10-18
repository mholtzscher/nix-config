{
  pkgs,
  lib,
  config,
  currentSystemUser,
  ...
}:
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

  # Mise owns the native sudo_local file and system-wide guest-login policy.
  # Explicitly disable management: the nix-darwin option defaults to enabled.
  security.pam.services.sudo_local.enable = false;

  # Home Manager no longer activates on Macs. Remove only its known home links,
  # never regular files, unexpected links, application bundles, or font files.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    retiredHmHome=${lib.escapeShellArg config.users.users.${currentSystemUser}.home}
    for retiredHmRelative in \
      '.cache/.keep' \
      '.local/state/.keep' \
      'Applications/Home Manager Apps' \
      'Library/Fonts/.home-manager-fonts-version'; do
      retiredHmPath="$retiredHmHome/$retiredHmRelative"
      if [[ -L "$retiredHmPath" ]]; then
        retiredHmTarget=$(readlink "$retiredHmPath")
        case "$retiredHmTarget" in
          /nix/store/*-home-manager-files/"$retiredHmRelative"|/nix/store/*-home-manager-generation/home-files/"$retiredHmRelative")
            if [[ -v DRY_RUN ]]; then
              printf >&2 'Would remove retired Home Manager link: %s\n' "$retiredHmPath"
            else
              printf >&2 'Removing retired Home Manager link: %s\n' "$retiredHmPath"
              rm -- "$retiredHmPath"
            fi
            ;;
        esac
      fi
    done
    unset retiredHmHome retiredHmRelative retiredHmPath retiredHmTarget
  '';

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
