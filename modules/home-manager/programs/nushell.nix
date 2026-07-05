{
  lib,
  pkgs,
  isDarwin,
  isWork,
  ...
}:
let
  sharedAliases = import ../shared-aliases.nix { inherit isWork; };
  dummySecretPath =
    if isDarwin then
      ''([(^${pkgs.getconf}/bin/getconf DARWIN_USER_TEMP_DIR | str trim) "agenix" "dummy-env"] | path join)''
    else
      ''([$env.XDG_RUNTIME_DIR "agenix" "dummy-env"] | path join)'';
  sideshowTokenPath =
    if isDarwin then
      ''([(^${pkgs.getconf}/bin/getconf DARWIN_USER_TEMP_DIR | str trim) "agenix" "sideshow-token"] | path join)''
    else
      ''([$env.XDG_RUNTIME_DIR "agenix" "sideshow-token"] | path join)'';
in
{
  programs = {
    nushell = {
      enable = true;
      extraConfig = ''
        use std/log;

        # Add local bin and homebrew to PATH
        $env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin" | prepend "/opt/homebrew/sbin" | prepend "/opt/homebrew/bin")

        ${builtins.readFile ../files/nushell/functions.nu}
      '';
      shellAliases = sharedAliases.shellAliases;
      environmentVariables = lib.mkIf (!isWork) {
        DUMMY_SECRET = lib.hm.nushell.mkNushellInline ''
          (open --raw ${dummySecretPath} | str trim)
        '';
        SIDESHOW_URL = "https://sideshow.sh";
        SIDESHOW_TOKEN = lib.hm.nushell.mkNushellInline ''
          (open --raw ${sideshowTokenPath} | str trim)
        '';
      };
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
