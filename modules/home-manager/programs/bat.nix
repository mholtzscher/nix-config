{
  pkgs,
  ...
}:
{
  programs = {
    bat = {
      enable = true;
      config = {
        theme = "tokyo-night";
      };
      themes = {
        tokyo-night = {
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "tokyonight.nvim";
            rev = "057ef5d260c1931f1dffd0f052c685dcd14100a3";
            sha256 = "sha256-1xZhQR1BhH2eqax0swlNtnPWIEUTxSOab6sQ3Fv9WQA=";
          };
          file = "extras/sublime/tokyonight_night.tmTheme";
        };
        catppuccin-mocha = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "6810349";
            sha256 = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
          };
          file = "themes/Catppuccin Mocha.tmTheme";
        };
      };
    };
  };
}
