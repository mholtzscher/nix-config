{ pkgs, ... }:
{
  catppuccin.tmux.enable = true;

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    sensibleOnTop = true;
    extraConfig = ''
      set-option -g default-shell "${pkgs.nushell}/bin/nu"
    '';

    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      vim-tmux-navigator
      yank
    ];
  };
}
