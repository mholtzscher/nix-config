{ ... }:
{
  programs = {
    mise = {
      enable = true;
      globalConfig = {
        tools = {
          "github:backnotprop/plannotator" = "0.19.0";
        };
      };
    };
  };
}
