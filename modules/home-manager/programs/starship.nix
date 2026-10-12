{ config, lib, ... }:
{
  # Mise owns Starship and its writable config, including the Catppuccin palette.
  catppuccin.starship.enable = false;
  programs.zsh.initContent = lib.mkOrder 1900 ''
    if [[ $TERM != "dumb" ]]; then
      eval "$(${lib.getExe config.programs.mise.package} exec -- starship init zsh)"
    fi
  '';
  programs.nushell = {
    extraEnv = ''
      mkdir ~/.cache/starship
      ^${lib.getExe config.programs.mise.package} exec -- starship init nu | save --force ~/.cache/starship/init.nu
    '';
    extraConfig = lib.mkOrder 1700 ''
      use ~/.cache/starship/init.nu
    '';
  };
}
