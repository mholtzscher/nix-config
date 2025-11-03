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
        # font-family = "GoMono Nerd Font";
        # font-family = "BlexMono Nerd Font Mono";
        # font-family = "Terminess Nerd Font";
        # font-family = "Iosevka Nerd Font Mono";
        font-family = "Iosevka Nerd Font";
        # font-family = "JetBrains Mono";
        #font-family-bold = "Iosevka NFM Bold"
        #font-family-italic = "Iosevka NFM Italic"
        #font-family-bold-italic = "Iosevka NFM Bold Italic"
        font-size = if pkgs.stdenv.isDarwin then "13" else "11";

        # theme = "catppuccin-mocha";

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
          "${inputs.ghostty-shader-playground}/public/shaders/cursor_smear_rainbow.glsl"
          # "${inputs.ghostty-shader-playground}/public/shaders/party_sparks.glsl"
        ];
      };
    };
  };
}
