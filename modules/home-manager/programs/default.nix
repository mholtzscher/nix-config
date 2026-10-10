{ ... }:
{
  imports = [
    ./direnv.nix
    ./ghostty.nix
    ./git.nix
    ./herdr.nix
    ./mise.nix
    ./nh.nix
    ./neovim.nix
    ./nushell.nix
    ./podman.nix
    ./ssh.nix
    ./webapps.nix # NixOS-only (has platform guard inside)
    ./zsh.nix
  ];
}
