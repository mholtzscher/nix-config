# NixOS Wayland module
# XDG portals, Niri, DMS, XWayland support
{
  flake.modules.nixos.wayland =
    { pkgs, ... }:
    {
      # Environment variables for Wayland
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

      # XDG portals for Wayland
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gnome # For Niri screencasting support
          pkgs.xdg-desktop-portal-gtk # For better GTK/GNOME app compatibility
        ];
      };

      # System packages for Wayland/XWayland
      environment.systemPackages = with pkgs; [
        wl-clipboard
        chromium

        # XWayland integration via xwayland-satellite (recommended by Niri)
        xwayland-satellite
        xwayland
        xorg.xhost
        xorg.xdpyinfo
      ];

      programs = {
        # Niri window manager
        niri.enable = true;

        # DankMaterialShell (Wayland desktop shell)
        dank-material-shell = {
          enable = true;
          systemd.enable = true;
          systemd.target = "niri.service";
        };

        # Firefox for Wayland
        firefox.enable = true;
      };
    };
}
