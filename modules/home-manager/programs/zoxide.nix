{ config, lib, ... }:
{
  # Mise owns the binary; generate hooks from that version at shell startup.
  programs.zsh.initContent = lib.mkOrder 2000 ''
    eval "$(${lib.getExe config.programs.mise.package} exec -- zoxide init zsh)"
  '';
  programs.nushell = {
    extraEnv = ''
      mkdir ~/.cache/zoxide
      ^${lib.getExe config.programs.mise.package} exec -- zoxide init nushell | save --force ~/.cache/zoxide/init.nu
    '';
    extraConfig = lib.mkOrder 1800 ''
      source ~/.cache/zoxide/init.nu
    '';
  };
}
