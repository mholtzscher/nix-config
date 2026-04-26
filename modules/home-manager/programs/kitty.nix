{
  lib,
  config,
  isDarwin,
  ...
}:
let
  nuExe = lib.getExe config.programs.nushell.package;
in
{
  programs.kitty = {
    enable = true;

    font = {
      name = "Iosevka";
      size = if isDarwin then 13 else 11;
    };

    environment = lib.mkIf isDarwin {
      # kitty launched from macOS GUI (Spotlight/Dock) gets a minimal PATH.
      # Ensure nix profile and darwin system paths are available so tools
      # like zoxide, fd, fzf, etc. are found by the spawned shell.
      PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    };

    settings = {
      # Use nushell as the shell
      shell = nuExe;

      # Appearance (consistent with ghostty)
      background_opacity = "0.9";
      background_blur = lib.mkIf isDarwin 20;
      window_padding_width = 4;
      draw_minimal_borders = true;
      cursor_shape = "block";
      cursor_blink_interval = 0;
      mouse_hide_wait = 3.0;
      focus_follows_mouse = true;
      enable_audio_bell = false;

      # Tab bar
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";

      # Layouts: splits first for tmux/zellij-like pane behavior
      enabled_layouts = "splits,stack,tall,fat,grid";

      # Scrollback
      scrollback_lines = 10000;

      # Remote control for session-like scripting (kitty @)
      allow_remote_control = true;
      listen_on = "unix:/tmp/kitty-$USER";

      # macOS: treat Option as Alt so alt+ keybindings work
      macos_option_as_alt = lib.mkIf isDarwin "yes";
    };

    # Keybindings inspired by zellij's locked-mode shortcuts
    # kitty has no modal prefix, so these are direct alt+ shortcuts
    keybindings = {
      # ── Panes (kitty calls them "windows") ──
      "alt+n" = "new_window_with_cwd";
      "alt+d" = "launch --location=hsplit --cwd=current";
      "alt+r" = "launch --location=vsplit --cwd=current";
      "alt+h" = "neighboring_window left";
      "alt+j" = "neighboring_window down";
      "alt+k" = "neighboring_window up";
      "alt+l" = "neighboring_window right";
      "alt+shift+h" = "move_window left";
      "alt+shift+j" = "move_window down";
      "alt+shift+k" = "move_window up";
      "alt+shift+l" = "move_window right";
      "alt+x" = "close_window";
      "alt+z" = "toggle_layout stack";
      "alt+ctrl+r" = "start_resizing_window";

      # ── Tabs ──
      "alt+t" = "new_tab_with_cwd";
      "alt+w" = "close_tab";
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      "alt+5" = "goto_tab 5";
      "alt+6" = "goto_tab 6";
      "alt+7" = "goto_tab 7";
      "alt+8" = "goto_tab 8";
      "alt+9" = "goto_tab 9";
      "alt+left" = "previous_tab";
      "alt+right" = "next_tab";
      "alt+shift+left" = "move_tab_backward";
      "alt+shift+right" = "move_tab_forward";

      # ── Scrollback / search ──
      "alt+s" = "show_scrollback";

      # ── Sessionizer (replaces zellij zsm) ──
      "alt+f" = "launch --type=window --hold ${nuExe} -c ks";

      # ── Font size ──
      "alt+equal" = "change_font_size all +1.0";
      "alt+minus" = "change_font_size all -1.0";
    };
  };

  # Provide a sample session file for kitty --session
  home.file."${config.xdg.configHome}/kitty/sessions/default.session".text = ''
    # Kitty session file
    # Launch with: kitty --session ~/.config/kitty/sessions/default.session

    new_tab home
    cd ~
    launch nu

    new_tab code
    cd ~/code
    launch nu
  '';
}
