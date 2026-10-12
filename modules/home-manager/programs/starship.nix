{ config, lib, ... }:
{
  # Mise owns Starship and its writable config, including the Catppuccin palette.
  catppuccin.starship.enable = false;
  programs.zsh.initContent = lib.mkOrder 1900 ''
    if [[ $TERM != "dumb" ]]; then
      eval "$(${lib.getExe config.programs.mise.package} exec -- starship init zsh)"
    fi
  '';
}
