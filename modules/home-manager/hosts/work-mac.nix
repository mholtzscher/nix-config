{ pkgs, lib, ... }:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac

  # Work-specific programs and packages
  home.packages = with pkgs; [
    # macOS-only packages
    aerospace
    mkalias
    pokemon-colorscripts-mac

    # Work-specific tools can be added here
  ];

  # Disable atuin sync on work Mac
  programs.atuin.settings = {
    auto_sync = lib.mkForce false;
    sync_address = lib.mkForce "";
  };

  # Disable beads MCP server on work Mac
  programs.opencode.settings.mcp.beads.enabled = lib.mkForce false;

  # Work-specific environment or configurations
  # No Discord on work Mac (not in packages)
}
