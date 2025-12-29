{ inputs, ... }:
{
  # Git & version control feature group

  imports = [
    ./git.nix
    ./delta.nix
    ./gh.nix
    ./gh-dash.nix
    ./lazygit.nix
    ./jujutsu.nix
  ];
}
