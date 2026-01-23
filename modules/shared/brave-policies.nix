# Shared Brave browser policy definitions
# These policies are consumed by both darwin and nixos modules
# Policy reference: https://chromeenterprise.google/policies/
{
  # ============================================
  # Disable Brave bloat features
  # ============================================
  BraveRewardsDisabled = true;
  BraveWalletDisabled = true;
  BraveVPNDisabled = true;
  BraveAIChatEnabled = false;
  BraveNewsDisabled = true;
  BraveTalkDisabled = true;

  # ============================================
  # Disable telemetry
  # ============================================
  BraveP3AEnabled = false;
  MetricsReportingEnabled = false;
  # Don't send URLs to Google for Safe Browsing checks
  SafeBrowsingExtendedReportingEnabled = false;
  # Disable URL-keyed anonymized data collection
  UrlKeyedAnonymizedDataCollectionEnabled = false;

  # ============================================
  # Privacy hardening
  # ============================================
  # Prevent WebRTC from leaking local/public IP addresses
  # Options: "default", "default_public_and_private_interfaces",
  #          "default_public_interface_only", "disable_non_proxied_udp"
  WebRtcIPHandling = "disable_non_proxied_udp";

  # Block third-party cookies
  BlockThirdPartyCookies = true;

  # Disable network prediction (prefetching) - sends URLs to Google
  # 0 = always predict, 1 = predict on wifi, 2 = never predict
  NetworkPredictionOptions = 2;

  # Disable search suggestions (sends keystrokes to search engine)
  SearchSuggestEnabled = false;

  # Disable Privacy Sandbox / Topics API (Google's cookie replacement)
  PrivacySandboxPromptEnabled = false;
  PrivacySandboxAdMeasurementEnabled = false;
  PrivacySandboxAdTopicsEnabled = false;
  PrivacySandboxSiteEnabledAdsEnabled = false;

  # ============================================
  # Security hardening
  # ============================================
  # Strict site isolation (each site runs in separate process)
  SitePerProcess = true;

  # Don't allow users to bypass SSL certificate errors
  SSLErrorOverrideAllowed = false;

  # Force HTTPS-only mode
  # Options: "allowed" (off), "force_enabled" (strict), "enabled" (with fallback)
  HttpsOnlyMode = "force_enabled";

  # ============================================
  # Disable built-in password manager
  # (Use a dedicated manager like 1Password/Bitwarden instead)
  # ============================================
  PasswordManagerEnabled = false;

  # Also disable autofill for credit cards and addresses
  AutofillCreditCardEnabled = false;
  AutofillAddressEnabled = false;
}
