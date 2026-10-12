# Personal Mac-specific Homebrew packages
{ ... }:
{
  homebrew = {
    taps = [
      "wontaeyang/hrm"
    ];
    casks = [
      "1password"
      # "capacities"
      "hrm"
    ];
    masApps = {
      # "WhatsApp" = 310633997;
    };
  };
}
