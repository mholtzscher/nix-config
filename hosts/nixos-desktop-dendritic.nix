# NixOS Desktop - Host Configuration
# References dendritic modules but defined separately to avoid recursion
{ inputs, ... }:
let
  user = "michael";
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs user;
    self = inputs.self;
    isWork = false;
  };
  modules = [
    # Import home-manager NixOS module
    inputs.home-manager.nixosModules.home-manager

    # Import catppuccin
    inputs.catppuccin.nixosModules.catppuccin

    # Import Niri
    inputs.niri.nixosModules.niri

    # Import DMS
    inputs.dms.nixosModules.default
    inputs.dms.nixosModules.greeter

    # Legacy NixOS system config (hardware, services, users, etc.)
    ./nixos/nixos-desktop/default.nix

    # Compatibility: legacy host sets user shell = zsh
    { programs.zsh.enable = true; }

    # Required by legacy config (NVIDIA, etc.)
    { nixpkgs.config.allowUnfree = true; }

    # Home-manager configuration
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inherit inputs user;
          self = inputs.self;
          isWork = false;
          isDarwin = false;
          isLinux = true;
          currentSystemName = "nixos-desktop";
          currentSystemUser = user;
        };
        users.${user} = lib.mkForce {
          home.stateVersion = "24.11";
          programs.home-manager.enable = true;
          imports = [
            # Core CLI tools - from dendritic modules
            inputs.self.modules.homeManager.bat
            inputs.self.modules.homeManager.eza
            inputs.self.modules.homeManager.fzf
            inputs.self.modules.homeManager.ripgrep
            inputs.self.modules.homeManager.zoxide
            inputs.self.modules.homeManager.fd

            # Shell + prompt + env
            inputs.self.modules.homeManager.zsh
            inputs.self.modules.homeManager.starship
            inputs.self.modules.homeManager.direnv
            inputs.self.modules.homeManager.atuin

            # SSH
            inputs.self.modules.homeManager.ssh

            # Development tools - from dendritic modules
            inputs.self.modules.homeManager.git

            # GitHub + JSON + monitoring
            inputs.self.modules.homeManager.gh
            inputs.self.modules.homeManager.gh-dash
            inputs.self.modules.homeManager.jq
            inputs.self.modules.homeManager.btop

            # Tooling
            inputs.self.modules.homeManager.mise
            inputs.self.modules.homeManager.carapace
            inputs.self.modules.homeManager.k9s
            inputs.self.modules.homeManager.lazydocker
            inputs.self.modules.homeManager.lazygit

            # JS runtime
            inputs.self.modules.homeManager.bun

            # Catppuccin theming
            inputs.catppuccin.homeModules.catppuccin
          ];
        };
      };
    }

  ];
}
