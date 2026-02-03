# Shared shell aliases
{ config, lib, ... }:
let
  cfg = config.myFeatures.aliases;
in
{
  options.myFeatures.aliases = {
    enable = lib.mkEnableOption "shared shell aliases" // {
      default = true;
      description = "Shared aliases for zsh and nushell";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.aliases = {
      programs.zsh.shellAliases = {
        ngc = "nix-collect-garbage -d";
        nfc = "nix flake check";

        of = "open-file";

        c = "clear";
        ll = "ls -al";
        ltd = "eza --tree --only-dirs --level 3";
        lg = "lazygit";
        n = "nvim";
        j = "just";
        ghd = "gh dash";

        clean = "git clean -Xdf";

        oc = "opencode";
        ocp = "sh ~/code/paytient/opencode/start";

        pbj = "pbpaste | jq";

        sso = "aws_change_profile";

        tf = "terraform";
      };

      programs.nushell.shellAliases = {
        ngc = "nix-collect-garbage -d";
        nfc = "nix flake check";

        of = "open-file";

        c = "clear";
        ll = "ls -al";
        ltd = "eza --tree --only-dirs --level 3";
        lg = "lazygit";
        n = "nvim";
        j = "just";
        ghd = "gh dash";

        clean = "git clean -Xdf";

        oc = "opencode";
        ocp = "sh ~/code/paytient/opencode/start";

        pbj = "pbpaste | jq";

        sso = "aws_change_profile";

        tf = "terraform";
      };
    };
  };
}
