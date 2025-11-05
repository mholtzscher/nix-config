{ pkgs, ... }:
{
  shellAliases = {
    # Nix/Darwin management
    # nb and nup are now platform-aware functions in nushell/functions.nu
    nfu = "nix flake update --flake ~/.config/nix-config";
    ngc = "nix-collect-garbage -d";

    # Navigation & development tools
    c = "clear";
    ll = "ls -al";
    ltd = "eza --tree --only-dirs --level 3";
    lg = "lazygit";
    n = "nvim";
    j = "just";
    ghd = "gh dash";

    # Chezmoi dotfile management
    # ch = "chezmoi";
    # chradd = "chezmoi re-add";
    # chap = "chezmoi apply";
    # chd = "chezmoi diff --pager delta";
    # chda = "chezmoi data";
    # chu = "chezmoi update";
    # chs = "chezmoi status";

    # Git utilities
    clean = "git clean -Xdf";

    oc = if pkgs.stdenv.isLinux then "steam-run bunx opencode-ai" else "opencode";

    # Clipboard utilities
    pbj = "pbpaste | jq";

    # System utilities
    # vim = "nvim";
    # cacheclear = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
    # ip = "dig +short myip.opendns.com @resolver1.opendns.com";
    # localip = "ipconfig getifaddr en0";
    # show = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
    # hide = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
    # weather = "curl wttr.in";

    # AWS utilities
    sso = "aws_change_profile";

    # Terraform
    tf = "terraform";

    # UVX
    specify = "uvx --from git+https://github.com/github/spec-kit.git specify";

    # Zellij
    zel = "zellij";
  };
}
