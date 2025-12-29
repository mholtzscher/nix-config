{ inputs, ... }:
{
  # Shell environment feature group
  # Contains: zsh, nushell, starship, atuin, carapace, zoxide

  imports = [
    ./zsh.nix
    ./nushell.nix
    ./starship.nix
    ./atuin.nix
    ./carapace.nix
    ./zoxide.nix
  ];
}
