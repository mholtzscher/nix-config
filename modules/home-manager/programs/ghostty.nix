{
  pkgs,
  lib,
  isDarwin,
  ...
}:
{
  programs = {
    ghostty = {
      enable = true;
      package = if isDarwin then null else pkgs.ghostty;
      settings = {
        font-family = "Iosevka Nerd Font";
        font-size = if isDarwin then "13" else "11";

        background-blur-radius = 20;
        background-opacity = 0.9;
        mouse-hide-while-typing = true;
        window-decoration = true;
        keybind = lib.mkIf isDarwin "global:cmd+alt+/=toggle_quick_terminal";
        macos-option-as-alt = lib.mkIf isDarwin true;

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
