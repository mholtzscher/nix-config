{
  config,
  lib,
  isDarwin,
  ...
}:
{
  # User-managed startup snippets are deployed outside Nix.
  programs = {
    bash.initExtra = ''
      source "${config.xdg.configHome}/shell/init.bash"
    '';
    fish.interactiveShellInit = ''
      source "${config.xdg.configHome}/shell/init.fish"
    '';
    zsh.initContent = lib.mkIf (!isDarwin) (
      lib.mkMerge [
        (lib.mkOrder 550 ''
          source "${config.xdg.configHome}/shell/completions.zsh"
        '')
        (lib.mkOrder 1000 ''
          source "${config.xdg.configHome}/shell/init.zsh"
        '')
      ]
    );
    nushell.extraConfig = lib.mkOrder 1000 ''
      source ${config.xdg.configHome}/shell/init.nu
    '';
  };
}
