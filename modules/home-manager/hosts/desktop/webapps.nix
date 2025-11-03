{ ... }:
{
  # Web applications as native apps
  # Uncomment and customize the apps you want to install
  programs.webapps = {
    enable = true;

    apps = [
      # Example configurations - uncomment and customize as needed:

      {
        name = "WhatsApp";
        url = "https://web.whatsapp.com";
        browser = "chromium";
        comment = "WhatsApp Web Client";
        # mimeType = "x-scheme-handler/mailto";
        categories = [
          "Network"
          "Chat"
        ];
      }

      # {
      #   name = "Gmail";
      #   url = "https://mail.google.com";
      #   browser = "firefox";
      #   comment = "Gmail Web Client";
      #   mimeType = "x-scheme-handler/mailto";
      #   categories = [ "Network" "Email" ];
      # }

      # {
      #   name = "Google Calendar";
      #   url = "https://calendar.google.com";
      #   browser = "firefox";
      #   comment = "Google Calendar";
      #   categories = [ "Office" "Calendar" ];
      # }

      # {
      #   name = "Notion";
      #   url = "https://notion.so";
      #   browser = "firefox";
      #   comment = "Notion Workspace";
      #   categories = [ "Office" "Development" ];
      # }

      # {
      #   name = "ChatGPT";
      #   url = "https://chat.openai.com";
      #   browser = "firefox";
      #   comment = "ChatGPT";
      #   categories = [ "Network" "Development" ];
      # }

      # {
      #   name = "Linear";
      #   url = "https://linear.app";
      #   browser = "firefox";
      #   comment = "Linear Issue Tracker";
      #   categories = [ "Development" "ProjectManagement" ];
      # }

      # Add custom icons by providing a path:
      # {
      #   name = "My App";
      #   url = "https://example.com";
      #   icon = ./icons/myapp.png;
      #   browser = "firefox";
      #   comment = "My Custom App";
      # }
    ];
  };
}
