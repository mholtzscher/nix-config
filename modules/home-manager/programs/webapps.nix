{
  config,
  lib,
  pkgs,
  isLinux,
  ...
}:
with lib;
let
  cfg = config.programs.webapps;

  # Web app configuration type
  webAppType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Display name of the web app";
      };

      url = mkOption {
        type = types.str;
        description = "URL to open";
        example = "https://example.com";
      };

      icon = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to icon file (PNG recommended)";
      };

      browser = mkOption {
        type = types.enum [
          "firefox"
          "chromium"
          "google-chrome"
        ];
        default = "firefox";
        description = "Browser to use for launching the app";
      };

      comment = mkOption {
        type = types.str;
        default = "";
        description = "Comment/description for the application";
      };

      mimeType = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional MIME type handler (e.g., x-scheme-handler/mailto)";
        example = "x-scheme-handler/mailto";
      };

      categories = mkOption {
        type = types.listOf types.str;
        default = [ "Network" ];
        description = "Desktop entry categories";
      };
    };
  };

  # Generate desktop entry for a web app
  makeDesktopEntry =
    app:
    let
      desktopName = builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower app.name);
      iconPath = if app.icon != null then app.icon else ""; # Use empty string if no icon
    in
    pkgs.writeTextFile {
      name = "${desktopName}.desktop";
      destination = "/share/applications/${desktopName}.desktop";
      text = ''
        [Desktop Entry]
        Version=1.0
        Name=${app.name}
        Comment=${if app.comment != "" then app.comment else app.name}
        Exec=${config.home.homeDirectory}/.local/bin/nixos-launch-webapp ${app.url} ${app.browser}
        Terminal=false
        Type=Application
        ${optionalString (iconPath != "") "Icon=${iconPath}"}
        StartupNotify=true
        Categories=${concatStringsSep ";" app.categories};
        ${optionalString (app.mimeType != null) "MimeType=${app.mimeType};"}
      '';
    };
in
{
  options.programs.webapps = {
    enable = mkEnableOption "web applications as native apps";

    apps = mkOption {
      type = types.listOf webAppType;
      default = [ ];
      description = "List of web applications to install";
      example = literalExpression ''
        [
          {
            name = "Gmail";
            url = "https://mail.google.com";
            icon = ./icons/gmail.png;
            browser = "firefox";
            comment = "Gmail Web Client";
            mimeType = "x-scheme-handler/mailto";
          }
        ]
      '';
    };
  };

  config = mkIf (cfg.enable && isLinux) {
    # Install launcher script
    home.file.".local/bin/nixos-launch-webapp" = {
      source = ../files/nixos-launch-webapp;
      executable = true;
    };

    # Install desktop entries for all configured apps
    home.packages = map makeDesktopEntry cfg.apps;
  };
}
