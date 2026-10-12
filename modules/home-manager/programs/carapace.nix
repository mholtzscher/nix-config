{ config, lib, ... }:
{
  # Generate completions from the Mise-managed version at shell startup.
  programs.zsh.initContent = lib.mkOrder 1800 ''
    source <(${lib.getExe config.programs.mise.package} exec -- carapace _carapace zsh)
  '';
}
