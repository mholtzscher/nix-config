{ config, lib, ... }:
{
  # Generate completions from the Mise-managed version at shell startup.
  programs.zsh.initContent = lib.mkOrder 1800 ''
    source <(${lib.getExe config.programs.mise.package} exec -- carapace _carapace zsh)
  '';
  programs.nushell = {
    extraEnv = ''
      mkdir ~/.cache/carapace
      ^${lib.getExe config.programs.mise.package} exec -- carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
    '';
    extraConfig = lib.mkOrder 1550 ''
      source ~/.cache/carapace/init.nu
    '';
  };
}
