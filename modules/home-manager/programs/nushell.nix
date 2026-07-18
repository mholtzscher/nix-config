{
  lib,
  pkgs,
  isDarwin,
  isWork,
  ...
}:
let
  sharedAliases = import ../shared-aliases.nix { inherit isWork; };
  ageSecretPath =
    name:
    if isDarwin then
      ''([(^${pkgs.getconf}/bin/getconf DARWIN_USER_TEMP_DIR | str trim) "agenix" "${name}"] | path join)''
    else
      ''([$env.XDG_RUNTIME_DIR "agenix" "${name}"] | path join)'';
  readAgeSecret =
    name:
    lib.hm.nushell.mkNushellInline ''
      (do {
        let secret = ${ageSecretPath name}
        mut attempts = 0
        while not ($secret | path exists) {
          if $attempts >= 100 { return "" }
          sleep 100ms
          $attempts += 1
        }
        open --raw $secret | str trim
      })
    '';
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
        DUMMY_SECRET = readAgeSecret "dummy-env";
        SIDESHOW_URL = "https://sideshow.sh";
        SIDESHOW_TOKEN = readAgeSecret "sideshow-token";
        AGENT_ARTIFACTS_BASE_URL = "https://artifacts.holtzscher.com";
        AGENT_ARTIFACTS_WRITE_KEY = readAgeSecret "agent-artifacts-write-key";
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
