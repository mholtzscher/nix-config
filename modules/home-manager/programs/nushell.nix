{
  config,
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
      (let secret = ${ageSecretPath name}; if ($secret | path exists) { open --raw $secret | str trim } else { "" })
    '';
in
{
  # Nix still supplies Nushell and its plugin registry; Mise owns Mac config.
  home.file = lib.optionalAttrs isDarwin {
    "Library/Application Support/nushell/config.nu".enable = false;
  };

  programs = {
    nushell = {
      enable = true;
      extraConfig = lib.mkMerge [
        (lib.mkOrder 400 ''
          # Set user paths before mise captures the shell PATH.
          $env.PATH = ($env.PATH | prepend "/opt/homebrew/sbin" | prepend "/opt/homebrew/bin" | prepend $"($env.HOME)/.bun/bin" | prepend $"($env.HOME)/.local/bin")
        '')
        (lib.mkOrder 1600 ''
          # Mise bootstrap generates native shell integrations.
          source ${config.xdg.configHome}/carapace/init.nu
          $env.FZF_CTRL_R_COMMAND = ""
          source ${config.xdg.configHome}/fzf/fzf.nu
          source ${config.xdg.configHome}/zoxide/init.nu
          use ${config.xdg.configHome}/starship/init.nu
          def --env yy [...args] {
            let tmp = (mktemp -t "yazi-cwd.XXXXX")
            ^yazi ...$args --cwd-file $tmp
            let cwd = (open $tmp)
            if $cwd != "" and $cwd != $env.PWD {
              cd $cwd
            }
            rm -fp $tmp
          }
        '')
        ''
          use std/log;

          ${builtins.readFile ../files/nushell/functions.nu}
          ${builtins.readFile ../files/nushell/herdr-nix-status.nu}
        ''
        (lib.mkOrder 2000 (
          if isWork then
            ''
              source ${config.xdg.configHome}/atuin/init.nu
            ''
          else
            ''
              if ("${config.age.secrets.atuin-key.path}" | path exists) {
                source ${config.xdg.configHome}/atuin/init.nu
              }
            ''
        ))
      ];
      shellAliases = sharedAliases.shellAliases;
      environmentVariables = {
        AI_COMMIT_MODEL = if isWork then "litellm/kimi-k-2.5" else "opencode-go/deepseek-v4.1-flash";
      }
      // lib.optionalAttrs (!isWork) {
        GITHUB_PERSONAL_ACCESS_TOKEN = readAgeSecret "github-pat";
        AGENT_ARTIFACTS_BASE_URL = "https://artifacts.holtzscher.com";
        AGENT_ARTIFACTS_WRITE_KEY = readAgeSecret "agent-artifacts-write-key";
        PI_FFF_MODE = "override";
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
        # pkgs.nushellPlugins.polars
      ];
    };
  };
}
