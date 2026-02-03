{ inputs, user, ... }:
{
  # Legacy Home Manager wiring for nixos-desktop.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
    };

    users.${user} =
      { ... }:
      {
        imports = [
          ../../../modules-legacy/home-manager/home.nix
          ../../../modules-legacy/home-manager/hosts/nixos-desktop/default.nix
        ];
      };
  };
}
