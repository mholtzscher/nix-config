{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  herdr = pkgs.herdr;
  # herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  herdr-focus-or-tab = pkgs.callPackage ../../../pkgs/herdr-focus-or-tab { };
  herdr-navigator = pkgs.callPackage ../../../pkgs/herdr-navigator { };
in
{
  home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${herdr}/bin/herdr integration install pi
    run ${herdr}/bin/herdr plugin link ${herdr-focus-or-tab} --enabled
    run ${herdr}/bin/herdr plugin link ${herdr-navigator} --enabled
  '';

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false
    [experimental]
    kitty_graphics = true

    [keys]
    prefix = "ctrl+g"

    remove_worktree = ["prefix+shift+u"]

    focus_pane_down = ["prefix+j", "alt+j"]
    focus_pane_up = ["prefix+k", "alt+k"]

    swap_pane_left = ["prefix+shift+h", "alt+shift+h"]
    swap_pane_down = ["prefix+shift+j", "alt+shift+j"]
    swap_pane_up = ["prefix+shift+k", "alt+shift+k"]
    swap_pane_right = ["prefix+shift+l", "alt+shift+l"]

    split_vertical = ["prefix+v", "alt+n"]
    split_horizontal = ["prefix+minus", "alt+d"]
    new_tab = ["prefix+c", "alt+t"]
    copy_mode = ["prefix+[", "prefix+s"]

    settings = "prefix+comma"
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

    [terminal]
    default_shell = "${pkgs.nushell}/bin/nu"

    [ui]
    prompt_new_tab_name = false
    hide_tab_bar_when_single_tab = true
    show_agent_labels_on_pane_borders = true

    [ui.sidebar.agents]
    rows = [
      ["state_icon", "workspace", "tab"],
      ["agent", "state_text"],
    ]
  '';
}
