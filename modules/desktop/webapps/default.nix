{ inputs, ... }:
{
  # Web applications as native apps

  flake.modules.homeManager.webapps =
    { pkgs, ... }:
    {
      imports = [ ./_module.nix ];

      programs.webapps = {
        enable = true;
        apps = [
          {
            name = "WhatsApp";
            url = "https://web.whatsapp.com";
            browser = "chromium";
            comment = "WhatsApp Web Client";
            categories = [
              "Network"
              "Chat"
            ];
          }
        ];
      };
    };
}
