{ inputs, ... }:
{
  # DevOps tools feature group

  imports = [
    ./k9s.nix
    ./lazydocker.nix
  ];
}
