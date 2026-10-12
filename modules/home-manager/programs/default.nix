{ ... }:
{
  imports = [
    ./ghostty.nix
    ./git.nix
    ./nh.nix
    ./neovim.nix
    ./podman.nix
    ./ssh.nix
    ./webapps.nix # NixOS-only (has platform guard inside)
    ./zsh.nix
  ];
}
