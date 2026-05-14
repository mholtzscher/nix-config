{ pkgs, ... }:
let
  enableZitree = true;
  zitreeWasm = if enableZitree then "${../../../pkgs/zitree/zitree.wasm}" else "@zitreeWasm@";

  zz = pkgs.writeShellScriptBin "zz" ''
    query="$*"
    if [ -z "$query" ]; then
      echo "Usage: zz <zoxide-query>" >&2
      exit 1
    fi

    dir=$(zoxide query "$query") || exit 1
    name="zz-$(basename "$dir")"

    if [ -n "''${ZELLIJ:-}" ]; then
      zellij action switch-session --layout compact --cwd "$dir" "$name"
    else
      cd "$dir" && exec zellij attach --create "$name"
    fi
  '';

  zzi = pkgs.writeShellScriptBin "zzi" ''
    dir=$(zoxide query -i)
    [ -z "$dir" ] && exit 0
    name="zz-$(basename "$dir")"
    zellij action switch-session --layout compact --cwd "$dir" "$name"
  '';

  zzs = pkgs.writeShellScriptBin "zzs" ''
    session=$(zellij list-sessions -n -s | fzf --prompt="Select session: " --height=40% --border)
    [ -z "$session" ] && exit 0
    zellij action switch-session "$session"
  '';
in
{
  programs.zellij = {
    enable = true;
  };

  home.packages = [
    zz
    zzi
    zzs
  ];

  # Use the KDL config file directly since home-manager's zellij module
  # doesn't properly escape attribute names with spaces in plugin configs
  xdg.configFile."zellij/config.kdl".text =
    builtins.replaceStrings
      [ "@zitreeWasm@" "@zziPath@" "@zzsPath@" ]
      [ zitreeWasm "${zzi}/bin/zzi" "${zzs}/bin/zzs" ]
      (builtins.readFile ../files/zellij.kdl);
}
