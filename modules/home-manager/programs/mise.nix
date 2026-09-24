{ lib, ... }:
{
  programs = {
    mise.enable = true;
    nushell.extraConfig = lib.mkMerge [
      (lib.mkOrder 500 ''
        # Home Manager generates mise's Nushell integration in a Nix build
        # sandbox, where PATH does not contain the user's profile.
        $env.__MISE_SHELL_PATH = ($env.PATH | str join (char esep))
      '')
      (lib.mkOrder 1500 ''
        $env.__MISE_ORIG_PATH = $env.__MISE_SHELL_PATH
        $env.PATH = ($env.__MISE_SHELL_PATH | split row (char esep) | prepend $"($env.HOME)/.local/share/mise/shims")
        hide-env __MISE_SHELL_PATH
      '')
    ];
  };
}
