{
  pkgs,
  ...
}:
{
  programs = {
    carapace = {
      enable = true;
      # enableFishIntegration = true;
    };
  };
}
