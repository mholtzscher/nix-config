# Cross-platform Brave browser installation
# Policies are managed at the system level (darwin/nixos modules)
{ ... }:
{
  programs.brave = {
    enable = true;

    # Extensions are installed via Chrome Web Store update mechanism (Linux only)
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
    ];
  };
}
