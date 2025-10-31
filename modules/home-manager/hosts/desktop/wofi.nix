{ pkgs, ... }:

{
  # Wofi application launcher for Hyprland
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Applications";
      filter_rate = 100;
      allow_markup = true;
      allow_images = true;
      image_size = 32;
      term = "ghostty";
      hide_scroll = true;
      dynamic_lines = true;
      exec_search = false;
      hide_search = false;
      sort_order = "alphabetical";
      insensitive = true;
      line_wrap = "off";
      columns = 1;
      matching = "fuzzy";
      adjacent_only = false;
      show_all = false;
      parse_search = false;
      search = "";
      natural_tab_order = false;
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "FiraCode Nerd Font", monospace;
        font-size: 14px;
        margin: 0;
        padding: 0;
      }

      window {
        background-color: #1e1e2e;
        color: #cad3f5;
        border: 2px solid #45475a;
        border-radius: 10px;
        box-shadow: 0 5px 20px rgba(0, 0, 0, 0.5);
      }

      #input {
        padding: 15px;
        background-color: #313244;
        color: #cad3f5;
        border-bottom: 2px solid #45475a;
        border-radius: 10px 10px 0 0;
      }

      #input:focus {
        background-color: #363c4a;
        border-bottom: 2px solid #89b4fa;
      }

      #scroll {
        margin: 10px;
        border-radius: 8px;
      }

      #inner-box {
        padding: 5px;
        background-color: #1e1e2e;
      }

      #outer-box {
        padding: 0;
      }

      #text {
        padding: 0;
        color: #cad3f5;
        margin: 0 10px;
      }

      #text:selected {
        color: #eed49f;
      }

      #entry {
        padding: 12px;
        border-radius: 8px;
        background-color: transparent;
        color: #cad3f5;
        margin: 2px 0;
      }

      #entry:selected {
        background-color: #5856d6;
        color: #eed49f;
        border-radius: 8px;
      }

      #entry:hover {
        background-color: rgba(88, 86, 214, 0.3);
        border-radius: 8px;
      }

      #img {
        padding: 5px;
        margin-right: 10px;
      }

      #box {
        margin: 0;
        padding: 0;
      }
    '';
  };
}
