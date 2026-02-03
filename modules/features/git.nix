# Git - Distributed version control system
# Demonstrates host-specific configuration in dendritic pattern
#
# This module exports a base git configuration. Hosts can either:
# 1. Use it directly (personal-mac)
# 2. Import it and override specific settings (work-mac)
# 3. Create a variant module (git-work.nix)
#
{ config, lib, ... }:
let
  cfg = config.myFeatures.git;
in
{
  options.myFeatures.git = {
    enable = lib.mkEnableOption "git configuration" // {
      default = true;
      description = "Enable git with sensible defaults";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.git =
      { pkgs, ... }:
      {
        programs.git = {
          enable = true;

          # Default identity (can be overridden per-host)
          userName = "Michael Holtzscher";
          userEmail = "michael@holtzscher.com";

          # Shared settings across all hosts
          settings = {
            column.ui = "auto";
            branch.sort = "-committerdate";
            tag.sort = "version:refname";
            init.defaultBranch = "main";

            diff = {
              algorithm = "histogram";
              colorMoved = "plain";
              mnemonicPrefix = true;
              renames = true;
            };

            push.autoSetupRemote = true;

            fetch = {
              prune = true;
              pruneTags = true;
              all = true;
            };

            rebase = {
              autoSquash = true;
              autoStash = true;
              updateRefs = true;
            };

            pull.rebase = true;
          };

          lfs.enable = true;
          delta.enable = true;
        };
      };
  };
}
