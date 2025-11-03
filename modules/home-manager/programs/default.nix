{ ... }:
{
  imports = [
    ./aerospace.nix # macOS-only (has platform guard inside)
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./carapace.nix
    ./delta.nix
    ./eza.nix
    ./fd.nix
    ./fish.nix
    ./fzf.nix
    ./gh-dash.nix
    ./gh.nix
    ./ghostty.nix
    ./git.nix
    ./go.nix
    ./helix.nix
    ./jujutsu.nix
    ./jq.nix
    ./k9s.nix
    ./lazydocker.nix
    ./lazygit.nix
    ./nushell.nix
    ./opencode.nix
    ./poetry.nix
    ./pyenv.nix
    ./ripgrep.nix
    ./ssh.nix
    ./starship.nix
    ./uv.nix
    # ./vicinae.nix # NixOS-only (imported directly in desktop.nix)
    ./webapps.nix # NixOS-only (has platform guard inside)
    ./wezterm.nix
    ./yazi.nix
    ./zed.nix
    ./zellij.nix
    ./zsh.nix
    ./zoxide.nix
  ];
}
