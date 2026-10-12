{ config, lib, ... }:
{
  # Mise owns Atuin and the shared, local-only config and theme.
  catppuccin.atuin.enable = false;
  programs.zsh.initContent = lib.mkOrder 2100 ''
    if [[ $options[zle] = on ]]; then
      eval "$(${lib.getExe config.programs.mise.package} exec -- atuin init zsh)"
    fi
  '';
  programs.nushell = {
    extraEnv = ''
      mkdir ~/.cache/atuin
      ^${lib.getExe config.programs.mise.package} exec -- atuin init nu
        | str replace 'name: atuin' 'name: atuin_ctrl_r'
        | save --force ~/.cache/atuin/init.nu
    '';
    # Load after fzf so Atuin retains Ctrl-R.
    extraConfig = lib.mkOrder 2000 ''
      source ~/.cache/atuin/init.nu
    '';
  };
}
