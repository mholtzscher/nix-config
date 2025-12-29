{ inputs, ... }:
{
  # Vicinae launcher for NixOS

  flake.modules.nixos.vicinae = {
    # Vicinae is home-manager only, NixOS module is a no-op
  };

  flake.modules.homeManager.vicinae =
    { ... }:
    {
      imports = [ inputs.vicinae.homeManagerModules.default ];

      services.vicinae = {
        enable = true;
        settings = {
          font = {
            normal = "Iosevka Nerd Font";
            size = 11;
          };
          theme.name = "catppuccin-mocha";
          window = {
            csd = true;
            opacity = 0.90;
            rounding = 10;
          };
          closeOnFocusLoss = true;
          faviconService = "google";
          popToRootOnClose = true;
          rootSearch.searchFiles = true;
        };
      };
    };
}
