{ ... }:
{
  imports = [
    # Migrated to dendritic pattern (modules/features/):
    # - bat, eza, fd, fzf, git, ripgrep, zoxide

    # Still in legacy:
    ./atuin.nix
    ./zen.nix
    ./btop.nix
    ./bun.nix
    ./carapace.nix
    ./delta.nix
    ./direnv.nix
    ./firefox.nix
    ./gh-dash.nix
    ./gh.nix
    ./ghostty.nix
    ./go.nix
    ./helix.nix
    ./jujutsu.nix
    ./jq.nix
    ./k9s.nix
    ./lazydocker.nix
    ./lazygit.nix
    ./mise.nix
    ./neovim.nix
    ./nushell.nix
    ./ollama.nix
    ./opencode.nix
    ./poetry.nix
    ./pyenv.nix
    ./ssh.nix
    ./starship.nix
    ./uv.nix
    ./webapps.nix # NixOS-only (has platform guard inside)
    ./yazi.nix
    ./zed.nix
    ./zellij.nix
    ./zsh.nix
  ];
}
