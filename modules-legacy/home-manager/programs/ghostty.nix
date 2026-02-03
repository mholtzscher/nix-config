{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  # Catppuccin theme is automatically managed by catppuccin/nix module
  programs = {
    ghostty = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
      settings = {
        font-family = "Iosevka Nerd Font";
        font-size = if pkgs.stdenv.isDarwin then "13" else "11";

        background-blur-radius = 20;
        background-opacity = 0.9;
        mouse-hide-while-typing = true;
        window-decoration = true;
        keybind = lib.mkIf pkgs.stdenv.isDarwin "global:cmd+alt+/=toggle_quick_terminal";
        macos-option-as-alt = lib.mkIf pkgs.stdenv.isDarwin true;

        window-height = 60;
        window-width = 200;
        quick-terminal-position = "center";
        quick-terminal-size = "60%";
        quick-terminal-screen = lib.mkIf pkgs.stdenv.isDarwin "macos-menu-bar";

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
