{ ... }:
{
  imports = [
    ./atuin.nix
    ./carapace.nix
    ./ghostty.nix
    ./git.nix
    ./mise.nix
    ./nh.nix
    ./neovim.nix
    ./nushell.nix
    ./podman.nix
    ./ssh.nix
    ./starship.nix
    ./webapps.nix # NixOS-only (has platform guard inside)
    ./yazi.nix
    ./zsh.nix
    ./zoxide.nix
  ];
}
