# Zen Browser (Linux only)
{
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
}
