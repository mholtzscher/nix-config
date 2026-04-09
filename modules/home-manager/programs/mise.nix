{ ... }:
{
  programs = {
    mise = {
      enable = true;
      globalConfig = {
        tools = {
          plannotator = "github:backnotprop/plannotator";
        };
      };
    };
  };
}
