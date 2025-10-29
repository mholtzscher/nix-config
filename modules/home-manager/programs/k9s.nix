{ pkgs, ... }:
let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "k9s";
    rev = "main";
    sha256 = "sha256-9h+jyEO4w0OnzeEKQXJbg9dvvWGZYQAO4MbgDn6QRzM=";
  };
in
{
  programs = {
    k9s = {
      enable = true;
      settings = {
        k9s = {
          ui = {
            skin = "catppuccin-mocha";
          };
        };
      };
      skins = {
        catppuccin-mocha = "${catppuccin}/dist/catppuccin-mocha.yaml";
      };
    };

  };
}
