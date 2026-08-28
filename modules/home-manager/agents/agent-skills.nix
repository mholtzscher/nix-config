{
  config,
  lib,
  inputs,
  isWork,
  pkgs,
  ...
}:
let
  herdr-annotate = pkgs.callPackage ../../../pkgs/herdr-annotate { };
in
{
  imports = [ inputs.agent-skills.homeManagerModules.default ];

  programs.agent-skills = {
    enable = true;

    sources = {
      local = {
        input = "mholtzscher-skills";
        idPrefix = "mholtzscher";
      };

      agent-artifacts = {
        input = "agent-artifacts";
        subdir = "skills";
        idPrefix = "mholtzscher";
      };

      anthropic = {
        input = "anthropic-skills";
        subdir = "skills";
        idPrefix = "anthropic";
      };

      # cloudflare = {
      #   input = "cloudflare-skills";
      #   subdir = "skills";
      #   idPrefix = "cloudflare";
      # };

      mattpocock = {
        input = "mattpocock-skills";
        idPrefix = "mattpocock";
        subdir = "skills/engineering";
      };

      mattpocock-productivity = {
        input = "mattpocock-skills";
        idPrefix = "mattpocock";
        subdir = "skills/productivity";
      };

      vercel = {
        input = "vercel-agent-browser";
        subdir = "skills";
        idPrefix = "vercel";
      };

      plannotator = {
        input = "plannotator-skills";
        subdir = "skills";
        idPrefix = "plannotator";
      };

      herdr = {
        input = "herdr";
        subdir = "skills";
        idPrefix = "herdr";
      };

      herdr-annotate = {
        path = "${herdr-annotate}/skills";
        idPrefix = "herdr-annotate";
      };

      dmmulroy = {
        input = "dmmulroy-dotfiles";
        subdir = "home/.agents/skills";
        idPrefix = "dmmulroy";
      };
    };

    skills.enable = [
      # "anthropic/frontend-design"
      "anthropic/skill-creator"
      "mattpocock/grill-with-docs"
      "mattpocock/improve-codebase-architecture"
      "mattpocock/codebase-design"
      "mattpocock/domain-modeling"
      "mattpocock/grilling"
      "mholtzscher/spec-planner"
      "vercel/agent-browser"
      "plannotator/html"
      "plannotator/html-wireframe"
      "plannotator/html-prototype"
      "plannotator/html-plan"
      "plannotator/html-diagram"
      "herdr/herdr"
      "dmmulroy/bro"
    ]
    ++ lib.optionals (!isWork) [
      # "cloudflare/agents-sdk"
      # "cloudflare/cloudflare"
      # "cloudflare/durable-objects"
      # "cloudflare/sandbox-sdk"
      # "cloudflare/web-perf"
      # "cloudflare/workers-best-practices"
      # "cloudflare/wrangler"
      "mholtzscher/upload-artifact"
      "mholtzscher/service-design"
      # "mholtzscher/zellij-tasks"
    ];

    skills.explicit.plannotator-tui = {
      from = "herdr-annotate";
      path = "plannotator-tui";
    };

    targets.pi = {
      enable = true;
      dest = "$HOME/.pi/agent/skills";
      structure = "symlink-tree";
    };

    targets.opencode = {
      enable = true;
      dest = "${config.xdg.configHome}/opencode/skills";
      structure = "symlink-tree";
    };
  };
}
