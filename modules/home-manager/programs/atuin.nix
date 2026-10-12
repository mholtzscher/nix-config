{ config, lib, ... }:
{
  # Mise owns Atuin and the shared, local-only config and theme.
  catppuccin.atuin.enable = false;
  programs.zsh.initContent = lib.mkOrder 2100 ''
    if [[ $options[zle] = on ]]; then
      eval "$(${lib.getExe config.programs.mise.package} exec -- atuin init zsh)"
    fi
  '';
}
