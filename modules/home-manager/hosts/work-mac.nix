{ pkgs, lib, ... }:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac

  # Work-specific programs and packages
  home.packages = with pkgs; [
    aerospace
    mkalias
    pokemon-colorscripts-mac
  ];

  # Disable atuin sync on work Mac
  programs.atuin.settings = {
    auto_sync = lib.mkForce false;
    sync_address = lib.mkForce "";
  };

  # Disable beads MCP server on work Mac
  programs.opencode.settings.mcp.beads.enabled = lib.mkForce false;
}
