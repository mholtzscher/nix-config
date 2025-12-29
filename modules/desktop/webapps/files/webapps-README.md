# Web Apps as Native Apps

This system allows you to install web applications as native desktop applications on NixOS.

## Overview

The web app system consists of:
- **Launcher script** (`nixos-launch-webapp`) - Opens URLs in browser windows
- **NixOS module** (`programs.webapps`) - Declaratively configure web apps
- **Desktop entries** - Apps appear in your application launcher (Wofi, Rofi, etc.)

## Configuration

Configure web apps in `modules/home-manager/hosts/desktop/webapps.nix`:

```nix
{
  programs.webapps = {
    enable = true;
    
    apps = [
      {
        name = "Gmail";
        url = "https://mail.google.com";
        browser = "firefox";
        comment = "Gmail Web Client";
        mimeType = "x-scheme-handler/mailto";  # Optional
        categories = [ "Network" "Email" ];
      }
      {
        name = "ChatGPT";
        url = "https://chat.openai.com";
        browser = "firefox";
        comment = "ChatGPT";
        categories = [ "Network" "Development" ];
      }
    ];
  };
}
```

## Options

Each app supports:

- **name** (required): Display name in launcher
- **url** (required): Web URL to open
- **browser** (default: "firefox"): Browser to use
  - Options: `firefox`, `chromium`, `google-chrome`, `brave`
- **comment** (optional): Description shown in launcher
- **icon** (optional): Path to PNG icon file
- **mimeType** (optional): MIME type handler (e.g., `x-scheme-handler/mailto`)
- **categories** (default: ["Network"]): Desktop entry categories

## Adding Custom Icons

1. Create an icons directory:
   ```bash
   mkdir -p modules/home-manager/files/webapps/icons
   ```

2. Add your PNG icons to the directory

3. Reference in configuration:
   ```nix
   {
     name = "My App";
     url = "https://example.com";
     icon = ../../files/webapps/icons/myapp.png;
   }
   ```

## Browser Modes

Different browsers launch web apps differently:

- **Firefox**: Uses `--new-window --kiosk` for fullscreen app mode
- **Chromium/Chrome/Brave**: Uses `--app=URL` for standalone window

## Desktop Categories

Common categories for organizing apps:
- `Network` - Web-based apps
- `Email` - Email clients
- `Office` - Productivity apps
- `Development` - Developer tools
- `Graphics` - Design/media apps
- `ProjectManagement` - Project tracking

## Example Apps

Common web apps you might want to install:

```nix
apps = [
  # Communication
  {
    name = "Gmail";
    url = "https://mail.google.com";
    browser = "firefox";
    mimeType = "x-scheme-handler/mailto";
    categories = [ "Network" "Email" ];
  }
  
  # Productivity
  {
    name = "Notion";
    url = "https://notion.so";
    browser = "firefox";
    categories = [ "Office" ];
  }
  {
    name = "Google Calendar";
    url = "https://calendar.google.com";
    browser = "firefox";
    categories = [ "Office" "Calendar" ];
  }
  
  # Development
  {
    name = "ChatGPT";
    url = "https://chat.openai.com";
    browser = "firefox";
    categories = [ "Network" "Development" ];
  }
  {
    name = "Linear";
    url = "https://linear.app";
    browser = "firefox";
    categories = [ "Development" "ProjectManagement" ];
  }
  {
    name = "GitHub";
    url = "https://github.com";
    browser = "firefox";
    categories = [ "Development" ];
  }
];
```

## Manual Launch

You can also launch web apps manually from the terminal:

```bash
nixos-launch-webapp https://example.com firefox
```

## Troubleshooting

**App doesn't appear in launcher:**
- Rebuild your configuration: `sudo nixos-rebuild switch`
- Check desktop entry: `ls ~/.nix-profile/share/applications/`
- Update desktop database: `update-desktop-database ~/.nix-profile/share/applications/`

**Browser not found:**
- Ensure the browser is installed in your system configuration
- The launcher will fall back to Firefox if available
- Check available browsers: `which firefox chromium`

**Icon not showing:**
- Verify icon path is correct and file exists
- Use PNG format for best compatibility
- Icons should be at least 256x256 pixels
