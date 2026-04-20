{ ... }:
{
  programs = {
    mise = {
      enable = true;
      globalConfig = {
        tools = {
          "github:backnotprop/plannotator" = "0.18.0";
        };
      };
    };
  };
}
