{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  herdr-navigator = pkgs.callPackage ../../../pkgs/herdr-navigator { };
in
{
  home.activation.herdrNavigator = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${herdr}/bin/herdr plugin link ${herdr-navigator} --enabled
  '';

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [keys]
    prefix = "ctrl+g"

    focus_pane_left = ["prefix+h", "alt+h"]
    focus_pane_down = ["prefix+j", "alt+j"]
    focus_pane_up = ["prefix+k", "alt+k"]
    focus_pane_right = ["prefix+l", "alt+l"]

    swap_pane_left = ["prefix+shift+h", "alt+shift+h"]
    swap_pane_down = ["prefix+shift+j", "alt+shift+j"]
    swap_pane_up = ["prefix+shift+k", "alt+shift+k"]
    swap_pane_right = ["prefix+shift+l", "alt+shift+l"]

    split_vertical = ["prefix+v", "alt+n", "alt+r"]
    split_horizontal = ["prefix+minus", "alt+d"]
    resize_mode = "prefix+r"
    close_pane = "prefix+x"
    zoom = ["prefix+z", "prefix+f"]
    cycle_pane_next = "prefix+tab"

    new_tab = ["prefix+c", "alt+t"]
    previous_tab = ["prefix+p", "alt+["]
    next_tab = ["prefix+n", "alt+]"]
    switch_tab = "prefix+1..9"

    copy_mode = ["prefix+[", "prefix+s"]
    edit_scrollback = "prefix+e"

    goto = ["prefix+g", "alt+z"]
    workspace_picker = "prefix+w"
    detach = ["prefix+q", "ctrl+q"]

    settings = "prefix+comma"
    help = "prefix+?"

    [[keys.command]]
    key = "prefix+t"
    type = "plugin_action"
    command = "herdr-navigator.open"
    description = "jump to anything"

    [theme]
    name = "catppuccin"

    [terminal]
    default_shell = "${pkgs.nushell}/bin/nu"
  '';
}
