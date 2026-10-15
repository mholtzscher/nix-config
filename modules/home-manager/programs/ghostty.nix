{ isDarwin, ... }:
{
  # Mise owns the writable config, theme, shader, and native macOS app.
  # Keep the Linux package for NixOS desktop integration; Wanda disables it.
  programs.ghostty.enable = !isDarwin;
  catppuccin.ghostty.enable = false;
}
