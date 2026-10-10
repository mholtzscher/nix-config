{ ... }:
{
  imports = [
    ./ghostty.nix
    ./git.nix
    ./herdr.nix
    ./nh.nix
    ./neovim.nix
    ./nushell.nix
    ./podman.nix
    ./shell.nix
    ./ssh.nix
    ./webapps.nix # NixOS-only (has platform guard inside)
    ./zsh.nix
  ];
}
