{ ... }:

{
  programs.hyprpanel = {
    enable = true;
    systemd.enable = true;

    settings = {
      theme = {
        bar = {
          menus = "rgba(26, 34, 46, 0.8)";
          primary_container = "rgba(41, 50, 65, 0.8)";
          secondary_container = "rgba(56, 62, 77, 0.8)";
          surface = "rgba(26, 34, 46, 0.8)";
          surface_variant = "rgba(41, 50, 65, 0.8)";
          on_surface = "rgba(192, 202, 245, 1)";
          on_surface_variant = "rgba(125, 139, 178, 1)";
          outline = "rgba(125, 139, 178, 1)";
          outline_variant = "rgba(56, 62, 77, 1)";
        };
        powermenu = {
          primary_container = "rgba(214, 112, 214, 1)";
          on_primary_container = "rgba(26, 34, 46, 1)";
        };
      };
      # launcher = {
      #   icon = "";
      # };
      workspaces = {
        show_icons = true;
        workspaces = 5;
        numbered_active_indicator = "name";
        monitorSpecific = false;
        hideUnoccupied = false;
      };
      clock = {
        format = "%H:%M";
      };
      notifications = {
        show = true;
        position = "top";
      };
    };
  };
}
