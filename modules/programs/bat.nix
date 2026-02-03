# Bat - A cat clone with syntax highlighting and Git integration
{
  flake.modules.homeManager.bat = {
    programs.bat = {
      enable = true;
      # Theme is managed by catppuccin globally
    };
  };
}
