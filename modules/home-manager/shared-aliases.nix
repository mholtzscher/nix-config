{ ... }:
{
  shellAliases = {
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

    specify = "uvx --from git+https://github.com/github/spec-kit.git specify";

    ze = "zellij";
  };
}
