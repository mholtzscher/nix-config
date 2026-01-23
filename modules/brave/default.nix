# Brave browser policies - shared across all platforms
# https://chromeenterprise.google/policies/
# Brave-specific: https://support.brave.com/hc/en-us/articles/360039248271
{
  # Extensions (force-installed by ID)
  ExtensionInstallForcelist = [
    "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
  ];

  # Autofill
  AutofillAddressEnabled = false;
  AutofillCreditCardEnabled = false;

  # Password manager
  PasswordManagerEnabled = false;

  # Telemetry & metrics
  MetricsReportingEnabled = false;
  SafeBrowsingExtendedReportingEnabled = false;

  # Privacy
  DoNotTrackEnabled = true;
  BlockThirdPartyCookies = true;

  # HTTPS
  HttpsOnlyMode = "force_enabled"; # "disallowed", "allowed", "force_enabled"

  # Downloads
  PromptForDownloadLocation = false;

  # Default browser
  DefaultBrowserSettingEnabled = false;

  # Homepage & startup
  HomepageIsNewTabPage = true;
  RestoreOnStartup = 1; # 1 = restore last session, 4 = open new tab, 5 = open URLs

  # Disable first run experience
  SuppressFirstRunBubble = true;

  # Picture in Picture
  PictureInPictureAllowed = true;

  # Brave-specific policies
  BraveRewardsDisabled = true;
  BraveWalletDisabled = true;
  BraveVPNDisabled = true;
  BraveAIChatEnabled = false;
  TorDisabled = false; # Keep Tor available
}
