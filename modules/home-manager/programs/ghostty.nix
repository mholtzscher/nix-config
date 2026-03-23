{
  pkgs,
  lib,
  config,
  isDarwin,
  ...
}:
let
  nuExe = lib.getExe config.programs.nushell.package;
  ghosttyKeybinds = [
    # "alt+n=new_split:auto"
    # "alt+d=new_split:down"
    # "alt+r=new_split:right"
    # "alt+h=goto_split:left"
    # "alt+left=goto_split:left"
    # "alt+j=goto_split:down"
    # "alt+down=goto_split:down"
    # "alt+k=goto_split:up"
    # "alt+up=goto_split:up"
    # "alt+l=goto_split:right"
    # "alt+right=goto_split:right"
  ]
  ++ lib.optionals isDarwin [
    "global:cmd+alt+/=toggle_quick_terminal"
  ];
in
{
  programs = {
    ghostty = {
      enable = true;
      package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      settings = {
        font-family = "Iosevka Nerd Font";
        font-size = if isDarwin then "13" else "11";

        background-blur-radius = 20;
        background-opacity = 0.9;
        mouse-hide-while-typing = true;
        window-decoration = true;
        keybind = ghosttyKeybinds;
        macos-option-as-alt = lib.mkIf isDarwin true;

        # command = nuExe;
        # shell-integration = "nushell";

        window-height = 60;
        window-width = 200;
        quick-terminal-position = "center";
        quick-terminal-size = "50%,50%";
        quick-terminal-screen = lib.mkIf isDarwin "macos-menu-bar";
        window-save-state = "never"; # seems to fix the quick-terminal-size not working right

        custom-shader = [
          # "${../files/ghostty/shaders/dvd_bounce_paytient.glsl}"
          # "${inputs.ghostty-shader-playground}/public/shaders/cursor_smear_rainbow.glsl"
          # "${../files/ghostty/shaders/cursor_smear_catppuccin.glsl}"
          # "${inputs.ghostty-shader-playground}/public/shaders/party_sparks.glsl"
        ];
      };
    };
  };
}
