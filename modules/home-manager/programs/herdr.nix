{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  herdr = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  herdr-focus-or-tab = pkgs.callPackage ../../../pkgs/herdr-focus-or-tab { };
  herdr-navigator = pkgs.callPackage ../../../pkgs/herdr-navigator { };
  herdr-worktree-picker = pkgs.callPackage ../../../pkgs/herdr-worktree-picker { };
in
{
  home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${herdr}/bin/herdr integration install pi
    run ${herdr}/bin/herdr plugin link ${herdr-focus-or-tab} --enabled
    run ${herdr}/bin/herdr plugin link ${herdr-navigator} --enabled
    run ${herdr}/bin/herdr plugin link ${herdr-worktree-picker} --enabled
  '';

  programs.herdr = {
    enable = true;
    package = herdr;
    settings = {
      onboarding = false;
      experimental.kitty_graphics = true;
      theme.custom.accent = "#f9e2af";

      keys = {
        prefix = "ctrl+g";
        switch_tab = [ ];
        switch_workspace = [ "prefix+1..9" ];
        new_worktree = [ ];
        remove_worktree = [ "prefix+shift+u" ];

        focus_pane_down = [
          "prefix+j"
          "alt+j"
        ];
        focus_pane_up = [
          "prefix+k"
          "alt+k"
        ];

        swap_pane_left = [
          "prefix+shift+h"
          "alt+shift+h"
        ];
        swap_pane_down = [
          "prefix+shift+j"
          "alt+shift+j"
        ];
        swap_pane_up = [
          "prefix+shift+k"
          "alt+shift+k"
        ];
        swap_pane_right = [
          "prefix+shift+l"
          "alt+shift+l"
        ];

        split_vertical = [
          "prefix+v"
          "alt+n"
        ];
        split_horizontal = [
          "prefix+minus"
          "alt+d"
        ];
        new_tab = [
          "prefix+c"
          "alt+t"
        ];
        copy_mode = [
          "prefix+["
          "prefix+s"
        ];

        settings = "prefix+comma";
        command = [
          {
            key = "alt+l";
            type = "plugin_action";
            command = "herdr-focus-or-tab.next";
            description = "focus next pane or tab";
          }
          {
            key = "alt+h";
            type = "plugin_action";
            command = "herdr-focus-or-tab.previous";
            description = "focus previous pane or tab";
          }
          {
            key = "prefix+shift+g";
            type = "plugin_action";
            command = "herdr-worktree-picker.create";
            description = "create worktree from branch";
          }
          {
            key = "alt+z";
            type = "plugin_action";
            command = "herdr-navigator.open";
            description = "jump to anything";
          }
        ];
      };

      terminal.default_shell = "${pkgs.nushell}/bin/nu";

      ui = {
        prompt_new_tab_name = false;
        hide_tab_bar_when_single_tab = true;
        show_agent_labels_on_pane_borders = true;
        sidebar.agents.rows = [
          [
            "state_icon"
            "workspace"
            "tab"
          ]
          [
            "agent"
            "state_text"
          ]
        ];
      };
    };
  };
}
