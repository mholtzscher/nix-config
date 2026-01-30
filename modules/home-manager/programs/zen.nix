# Cross-platform Zen browser installation with privacy policies
# Zen Browser is Firefox-based and uses Firefox policies
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.zen-browser = {
    enable = true;

    # Privacy and security policies (similar to Brave config)
    policies = {
      # Disable telemetry
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;

      # Disable Firefox accounts sync
      DisableFirefoxAccounts = false; # Keep enabled for potential use

      # Disable built-in password manager (use 1Password instead)
      PasswordManagerEnabled = false;

      # Block third-party cookies
      Cookies = {
        Allow = [ ];
        Block = [ ];
        Default = "third-party";
      };

      # Privacy settings
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };

      # Disable search suggestions (sends keystrokes to search engine)
      SearchSuggestEnabled = false;

      # HTTPS-Only mode
      HttpsOnlyMode = "enabled";

      # Disable Firefox VPN ads
      MozillaVPN = false;

      # Disable Firefox Relay ads
      FirefoxRelay = false;

      # Extensions to install
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/uBlock0@raymondhill.net/latest.xpi";
          installation_mode = "force_installed";
        };
        # 1Password
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/{d634138d-c276-4fc8-924b-40a0ea21d284}/latest.xpi";
          installation_mode = "force_installed";
        };
      };

      # Preferences
      Preferences = {
        # Disable WebRTC leak protection
        "media.peerconnection.enabled" = true;
        "media.peerconnection.ice.default_address_only" = true;
        "media.peerconnection.ice.no_host" = true;

        # Disable prefetching
        "network.prefetch-next" = false;
        "network.dns.disablePrefetch" = true;

        # Disable Safe Browsing (sends URLs to Google)
        "browser.safebrowsing.malware.enabled" = false;
        "browser.safebrowsing.phishing.enabled" = false;
        "browser.safebrowsing.downloads.enabled" = false;

        # Disable sponsored content
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      };
    };
  };
}
