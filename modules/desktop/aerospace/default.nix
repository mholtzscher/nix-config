{ inputs, ... }:
{
  # Aerospace window manager for macOS

  # Darwin system-level module (no-op, just for module reference)
  flake.modules.darwin.aerospace = { };

  # Home-manager module with actual configuration
  flake.modules.homeManager.aerospace =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.activation.aerospaceConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${config.home.homeDirectory}/.config/aerospace"
        run cp -f ${./files/aerospace.toml} "${config.home.homeDirectory}/.config/aerospace/aerospace.toml"
        run chmod u+w "${config.home.homeDirectory}/.config/aerospace/aerospace.toml"
      '';

      home.packages = with pkgs; [ aerospace ];

      # Raycast scripts for Aerospace
      home.file.".config/raycast/scripts/toggle-aerospace.sh" = {
        source = ./files/raycast/toggle-aerospace.sh;
        executable = true;
      };
      home.file.".config/raycast/scripts/aerospace-workspace-size.sh" = {
        source = ./files/raycast/aerospace-workspace-size.sh;
        executable = true;
      };
      home.file.".config/raycast/scripts/aerospace-workspace-size-increment.sh" = {
        source = ./files/raycast/aerospace-workspace-size-increment.sh;
        executable = true;
      };
      home.file.".config/raycast/scripts/aerospace-workspace-size-decrement.sh" = {
        source = ./files/raycast/aerospace-workspace-size-decrement.sh;
        executable = true;
      };
    };
}
