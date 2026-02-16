{ pkgs, ... }:
{
  # Desktop-specific system packages
  environment.systemPackages = with pkgs; [
    # Development tools
    python314
    rustc
    cargo
    gcc
    gnumake
    vscode

    libnotify

    # Screenshot tools for Wayland
    grim
    slurp
    wl-clipboard
  ];

  # 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "michael" ];
  };

  # Install Nerd Font packages (matching macOS configuration)
  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
  ];

  # System-wide font configuration
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Iosevka Nerd Font Mono" ];
      sansSerif = [ "Iosevka Nerd Font" ];
      serif = [ "Iosevka Nerd Font" ];
    };
    # Better font rendering
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel.rgba = "rgb";
  };
}
