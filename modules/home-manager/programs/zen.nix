# Cross-platform Zen browser installation with privacy policies
# Zen Browser is Firefox-based and uses Firefox policies
{
  pkgs,
  ...
}:
{
  programs.zen-browser = {
    enable = true;

    # Privacy and security policies
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

      # Block third-party cookies
      Cookies = {
        Allow = [ ];
        Block = [ ];
        Default = "third-party";
      };

      SearchSuggestEnabled = false;
      HttpsOnlyMode = "enabled";
      MozillaVPN = false;
      FirefoxRelay = false;

      # Extensions to install (1Password is unfree, must use ExtensionSettings)
      # ExtensionSettings = {
      #   # 1Password - installed via Mozilla store due to unfree license
      #   "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
      #     install_url = "https://addons.mozilla.org/firefox/downloads/latest/{d634138d-c276-4fc8-924b-40a0ea21d284}/latest.xpi";
      #     installation_mode = "force_installed";
      #   };
      # };

      # Preferences
      # Preferences = {
      #   # Disable WebRTC leak protection
      #   "media.peerconnection.enabled" = true;
      #   "media.peerconnection.ice.default_address_only" = true;
      #   "media.peerconnection.ice.no_host" = true;
      #
      #   # Disable prefetching
      #   "network.prefetch-next" = false;
      #   "network.dns.disablePrefetch" = true;
      #
      #   # Disable Safe Browsing (sends URLs to Google)
      #   "browser.safebrowsing.malware.enabled" = false;
      #   "browser.safebrowsing.phishing.enabled" = false;
      #   "browser.safebrowsing.downloads.enabled" = false;
      #
      #   # Disable sponsored content
      #   "browser.newtabpage.activity-stream.showSponsored" = false;
      #   "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      # };
    };

    # Extensions installed via rycee's firefox-addons
    # profiles.default.extensions.packages =
    #   with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
    #     vimium
    #     darkreader
    #     privacy-badger
    #   ];

    # Search engines configuration
  #   profiles.default.search = {
  #     force = true;
  #     engines = {
  #       "NixOS Packages" = {
  #         urls = [
  #           {
  #             template = "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={searchTerms}";
  #           }
  #         ];
  #         icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  #         definedAliases = [ "@nix" ];
  #       };
  #
  #       "GitHub" = {
  #         urls = [
  #           {
  #             template = "https://github.com/search?q={searchTerms}&type=repositories";
  #           }
  #         ];
  #         icon = "https://github.com/favicon.ico";
  #         definedAliases = [ "@gh" ];
  #       };
  #     };
  #   };
  };
}
