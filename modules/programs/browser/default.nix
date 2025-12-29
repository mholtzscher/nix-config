{ inputs, ... }:
{
  # Browser feature group

  imports = [
    ./firefox.nix
  ];

  flake.modules.homeManager.browser =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ firefox ];
    };
}
