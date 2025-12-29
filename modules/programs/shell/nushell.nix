{ inputs, ... }:
{
  flake.modules.homeManager.nushell =
    { pkgs, config, ... }:
    let
      sharedAliases = import ./files/_aliases.nix { inherit pkgs; };
    in
    {
      programs.nushell = {
        enable = true;
        extraConfig = ''
          use std/log;

          # Import naws as a Nushell overlay
          use ${inputs.naws}/naws/

          # Add local bin and homebrew to PATH
          $env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin" | prepend "/opt/homebrew/sbin" | prepend "/opt/homebrew/bin")

          ${builtins.readFile ./files/functions.nu}
        '';
        shellAliases = sharedAliases.shellAliases // { };
        settings = {
          edit_mode = "vi";
          show_banner = false;
          cursor_shape = {
            vi_insert = "line";
            vi_normal = "block";
          };
        };
        plugins = [
          pkgs.nushellPlugins.formats
          pkgs.nushellPlugins.polars
        ];
      };
    };
}
