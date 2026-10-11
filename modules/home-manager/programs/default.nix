{ ... }:
{
  imports = [
    ./atuin.nix
    ./btop.nix
    ./bun.nix
    ./carapace.nix
    ./direnv.nix
    ./fzf.nix
    ./ghostty.nix
    ./git.nix
    ./go.nix
    ./mise.nix
    ./nh.nix
    ./neovim.nix
    ./nushell.nix
    ./podman.nix
    ./ssh.nix
    ./starship.nix
    ./uv.nix
    ./webapps.nix # NixOS-only (has platform guard inside)
    ./yazi.nix
    ./zsh.nix
    ./zoxide.nix
  ];
}
