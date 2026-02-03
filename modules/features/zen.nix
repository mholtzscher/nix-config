# Zen Browser (Linux only)
{ config, lib, ... }:
let
  cfg = config.myFeatures.zen;
in
{
  options.myFeatures.zen = {
    enable = lib.mkEnableOption "zen-browser configuration" // {
      default = true;
      description = "Enable zen-browser (Linux only)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.zen =
      {
        pkgs,
        inputs,
        ...
      }:
      {
        imports = [ inputs.zen-browser.homeModules.default ];

        programs.zen-browser = {
          enable = pkgs.stdenv.isLinux;

          policies = {
            AutofillAddressEnabled = true;
            AutofillCreditCardEnabled = false;
            DisableAppUpdate = true;
            DisableFeedbackCommands = true;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            DisableTelemetry = true;
            DontCheckDefaultBrowser = true;
            NoDefaultBookmarks = true;
            OfferToSaveLogins = false;
            EnableTrackingProtection = {
              Value = true;
              Locked = true;
              Cryptomining = true;
              Fingerprinting = true;
            };

            Cookies = {
              Allow = [ ];
              Block = [ ];
              Default = "third-party";
            };

            SearchSuggestEnabled = false;
            HttpsOnlyMode = "enabled";
            MozillaVPN = false;
            FirefoxRelay = false;
          };
        };
      };
  };
}
