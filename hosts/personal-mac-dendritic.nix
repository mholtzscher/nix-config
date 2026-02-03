# Personal Mac (M1 Max) - Host Configuration
# References dendritic modules but defined separately to avoid recursion
{ inputs, ... }:
let
  user = "michael";
in
inputs.nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = {
    inherit inputs user;
    self = inputs.self;
    isWork = false;
  };
  modules = [
    # Import home-manager module
    inputs.home-manager.darwinModules.home-manager

    # Import nix-homebrew module
    inputs.nix-homebrew.darwinModules.nix-homebrew

    # Dendritic system modules
    inputs.self.modules.darwin.system
    inputs.self.modules.darwin.base
    inputs.self.modules.darwin.homebrewCommon
    inputs.self.modules.darwin.homebrewPersonalMac
    inputs.self.modules.darwin.hostPersonalMac

    # Dendritic home-manager wiring
    inputs.self.modules.darwin.hmPersonalMac

  ];
}
