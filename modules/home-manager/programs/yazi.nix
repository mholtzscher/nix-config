{
  pkgs,
  ...
}:
let
  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "BennyOe";
    repo = "tokyo-night.yazi";
    rev = "5f56364";
    sha256 = "sha256-4aNPlO5aXP8c7vks6bTlLCuyUQZ4Hx3GWtGlRmbhdto=";
  };
in
{
  programs = {
    yazi = {
      enable = true;

      flavors = {
        tokyonight = "${yazi-flavors}";
      };

      theme = {
        flavor = {
          dark = "tokyonight";
        };
      };

      settings = {
        mgr = {
          show_hidden = true;
          # sort_by = "mtime";
          # sort_dir_first = true;
          # sort_reverse = true;
        };
      };
    };
  };
}
