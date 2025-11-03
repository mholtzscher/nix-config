{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  sharedAliases = import ../shared-aliases.nix;
  
  # macOS-specific asdf configuration
  asdfConfig = lib.optionalString pkgs.stdenv.isDarwin ''
    # Configure asdf (macOS only via Homebrew)
    if ("/opt/homebrew/opt/asdf/libexec/asdf.nu" | path exists) {
      $env.ASDF_NU_DIR = "/opt/homebrew/opt/asdf/libexec"
      source "/opt/homebrew/opt/asdf/libexec/asdf.nu"
    }
  '';
in
{
  programs = {
    nushell = {
      enable = true;
      extraConfig = ''
        use std/log;

        ${asdfConfig}

        # Import naws as a Nushell overlay
        # overlay use ${inputs.naws}/naws as naws
        use ${inputs.naws}/naws/

        # Add local bin to PATH
        $env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin")

        ${builtins.readFile ../files/nushell/functions.nu}
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
