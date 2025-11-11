{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  sharedAliases = import ../shared-aliases.nix { inherit pkgs; };

  # macOS-specific asdf configuration
  asdfConfig = lib.optionalString pkgs.stdenv.isDarwin ''
    $env.ASDF_NU_DIR = "/opt/homebrew/opt/asdf/libexec"
    $env.ASDF_DIR = (
      if ($env | get --optional ASDF_NU_DIR | is-empty) == false {
        $env.ASDF_NU_DIR
      }
      else if ($env | get --optional ASDF_DIR | is-empty) == false {
        $env.ASDF_DIR
      } else {
        print --stderr "asdf: Either ASDF_NU_DIR or ASDF_DIR must not be empty"
        return
      }
    )

    let shims_dir = (
      if ( $env | get --optional ASDF_DATA_DIR | is-empty ) {
        $env.HOME | path join '.asdf'
      } else {
        $env.ASDF_DATA_DIR
      } | path join 'shims'
    )
    let asdf_bin_dir = ( $env.ASDF_DIR | path join 'bin' )

    $env.PATH = ( $env.PATH | split row (char esep) | where { |p| $p != $shims_dir } | prepend $shims_dir )
    $env.PATH = ( $env.PATH | split row (char esep) | where { |p| $p != $asdf_bin_dir } | prepend $asdf_bin_dir )
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
