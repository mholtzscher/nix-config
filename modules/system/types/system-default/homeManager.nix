{ inputs, ... }:
{
  flake.modules.homeManager.system-default = {
    # Catppuccin theming is now managed per-program
    # Programs like fzf, bat, etc. use catppuccin directly

    home.stateVersion = "24.11";
    programs.home-manager.enable = true;
  };
}
