{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  herdr-focus-or-tab = pkgs.callPackage ../../../pkgs/herdr-focus-or-tab { };
  herdr-navigator = pkgs.callPackage ../../../pkgs/herdr-navigator { };
in
{
  home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${herdr}/bin/herdr plugin link ${herdr-focus-or-tab} --enabled
    run ${herdr}/bin/herdr plugin link ${herdr-navigator} --enabled
  '';

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [keys]
    prefix = "ctrl+g"

    focus_pane_left = "prefix+h"
    focus_pane_down = ["prefix+j", "alt+j"]
    focus_pane_up = ["prefix+k", "alt+k"]
    focus_pane_right = "prefix+l"

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
    cycle_pane_previous = "prefix+shift+tab"

    new_tab = ["prefix+c", "alt+t"]
    previous_tab = ["prefix+p", "alt+["]
    next_tab = ["prefix+n", "alt+]"]
    switch_tab = "prefix+1..9"

    copy_mode = ["prefix+[", "prefix+s"]
    edit_scrollback = "prefix+e"

    goto = "prefix+g"
    workspace_picker = "prefix+w"
    detach = ["prefix+q", "ctrl+q"]

    settings = "prefix+comma"
    help = "prefix+?"

    [[keys.command]]
    key = "alt+l"
    type = "plugin_action"
    command = "herdr-focus-or-tab.next"
    description = "focus next pane or tab"

    [[keys.command]]
    key = "alt+h"
    type = "plugin_action"
    command = "herdr-focus-or-tab.previous"
    description = "focus previous pane or tab"

    [[keys.command]]
    key = "prefix+t"
    type = "plugin_action"
    command = "herdr-navigator.open"
    description = "jump to anything"

    [[keys.command]]
    key = "alt+z"
    type = "plugin_action"
    command = "herdr-navigator.open"
    description = "jump to anything"

    [theme]
    name = "catppuccin"

    [terminal]
    default_shell = "${pkgs.nushell}/bin/nu"

    [ui]
    prompt_new_tab_name = false
    hide_tab_bar_when_single_tab = true
    show_agent_labels_on_pane_borders = true
  '';
}
