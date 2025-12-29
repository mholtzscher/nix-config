# Unified host outputs for flake-parts
# This file is ignored by import-tree (due to _) and imported explicitly

{ inputs, ... }:
{
  flake = {
    darwinConfigurations = {
      "Michaels-M1-Max" = inputs.self.lib.mkDarwin "aarch64-darwin" "personal-mac";
      "Michael-Holtzscher-Work" = inputs.self.lib.mkDarwin "aarch64-darwin" "work-mac";
    };

    nixosConfigurations = {
      nixos-desktop = inputs.self.lib.mkNixos "x86_64-linux" "nixos-desktop";
      wanda = inputs.self.lib.mkNixos "x86_64-linux" "wanda";
    };
  };
}
