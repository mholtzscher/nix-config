{ isWork, ... }:
{
  programs = {
    mise = {
      enable = isWork;
    };
  };
}
