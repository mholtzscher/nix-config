{
  isLinux,
  pkgs,
  ...
}:
{
  programs.firefox = {
    enable = isLinux;

    policies = {
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "DisableFirefoxAccounts" = false;
      "DisableProfileRefresh" = true;
      "DisableTelemetry" = true;
      "DontCheckDefaultBrowser" = true;
      "DownloadDirectory" = "$\{home\}\\Downloads";
      "EnableTrackingProtection" = {
        "Value" = true;
        "Category" = "strict";
      };
      "Homepage" = {
        "URL" = "about:home";
        "Locked" = false;
        "StartPage" = "homepage";
      };
      "HttpsOnlyMode" = "enabled";
      "OfferToSaveLogins" = false;
      "OverrideFirstRunPage" = "";
      "PasswordManagerEnabled" = false;
      "PictureInPicture" = {
        "Enabled" = true;
        "Locked" = false;
      };
      "PromptForDownloadLocation" = false;
      "SkipTermsOfUse" = false;
      "SearchEngines" = {
        "Remove" = [
          "Bing"
          "Perplexity"
        ];
      };
    };

    profiles.default = {
      name = "Default";
      isDefault = true;

      # Allow catppuccin module to set extension settings
      extensions.force = true;

      settings = {
        # "browser.download.panel.shown" = true;
        "browser.uitour.enabled" = false;

        # Disable warn on quit
        # "browser.warnOnQuit" = false;
        # "browser.warnOnQuitShortcut" = false;
        # Vertical tabs
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;
        "sidebar.main.tools" = "history,bookmarks";

        # Layout
        # "browser.uiCustomization.state" = builtins.toJSON {
        #   placements = {
        #     # unified-extensions-area = [ ];
        #     # widget-overflow-fixed-list = [ ];
        #     nav-bar = [
        #       "back-button"
        #       "forward-button"
        #       "vertical-spacer"
        #       "stop-reload-button"
        #       "urlbar-container"
        #       "downloads-button"
        #       # "ublock0_raymondhill_net-browser-action"
        #       # "_testpilot-containers-browser-action"
        #       # "reset-pbm-toolbar-button"
        #       "unified-extensions-button"
        #     ];
        #     # toolbar-menubar = [ "menubar-items" ];
        #     # TabsToolbar = [ ];
        #     # vertical-tabs = [ "tabbrowser-tabs" ];
        #     # PersonalToolbar = [ "personal-bookmarks" ];
        #   };
        #   # seen = [
        #   #   "save-to-pocket-button"
        #   #   "developer-button"
        #   #   "ublock0_raymondhill_net-browser-action"
        #   #   "_testpilot-containers-browser-action"
        #   #   "screenshot-button"
        #   # ];
        #   # dirtyAreaCache = [
        #   #   "nav-bar"
        #   #   "PersonalToolbar"
        #   #   "toolbar-menubar"
        #   #   "TabsToolbar"
        #   #   "widget-overflow-fixed-list"
        #   #   "vertical-tabs"
        #   # ];
        #   # currentVersion = 23;
        #   # newElementCount = 10;
        # };
      };

      # Search engines configuration
      search = {
        force = true;

        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "NixOS Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          "NixOS Wiki" = {
            urls = [
              {
                template = "https://wiki.nixos.org/w/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@nw" ];
          };

          "GitHub" = {
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = [ "@gh" ];
          };
        };
      };
    };
  };
}
