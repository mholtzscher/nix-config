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
        input = "skills-mholtzscher";
        idPrefix = "mholtzscher";
      };

      agent-artifacts = {
        input = "skills-agent-artifacts";
        subdir = "skills";
        idPrefix = "mholtzscher";
      };

      anthropic = {
        input = "skills-anthropic";
        subdir = "skills";
        idPrefix = "anthropic";
      };

      # cloudflare = {
      #   input = "skills-cloudflare";
      #   subdir = "skills";
      #   idPrefix = "cloudflare";
      # };

      mattpocock = {
        input = "skills-mattpocock";
        idPrefix = "mattpocock";
        subdir = "skills/engineering";
      };

      mattpocock-productivity = {
        input = "skills-mattpocock";
        idPrefix = "mattpocock";
        subdir = "skills/productivity";
      };

      vercel = {
        input = "skills-vercel";
        subdir = "skills";
        idPrefix = "vercel";
      };

      plannotator = {
        input = "skills-plannotator";
        subdir = "skills";
        idPrefix = "plannotator";
      };

      pstack = {
        input = "skills-pstack";
        subdir = "pstack/skills";
        idPrefix = "pstack";
      };

      herdr = {
        input = "skills-herdr";
        subdir = "skills";
        idPrefix = "herdr";
      };

      humanlayer = {
        input = "skills-humanlayer";
        subdir = "plugins/show-me/skills";
        idPrefix = "humanlayer";
      };

      herdr-annotate = {
        path = "${herdr-annotate}/skills";
      };

      dmmulroy = {
        input = "skills-dmmulroy";
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
      "mattpocock/teach"
      "mholtzscher/spec-planner"
      "mholtzscher/go-test-effectiveness"
      "vercel/agent-browser"
      "plannotator/html"
      "plannotator/html-wireframe"
      "plannotator/html-prototype"
      "plannotator/html-plan"
      "plannotator/html-diagram"
      "plannotator-tui"
      "pstack/create-verification-skill"
      "pstack/maintain-verification-skill"
      "pstack/unslop"
      "herdr/herdr"
      "humanlayer/show-me"
      "dmmulroy/bro"
      "dmmulroy/write-discoverable-code"
    ]
    ++ lib.optionals (!isWork) [
      # "cloudflare/agents-sdk"
      # "cloudflare/cloudflare"
      # "cloudflare/durable-objects"
      # "cloudflare/sandbox-sdk"
      # "cloudflare/web-perf"
      # "cloudflare/workers-best-practices"
      # "cloudflare/wrangler"
      # "mholtzscher/upload-artifact"
      "mholtzscher/service-design"
      # "mholtzscher/zellij-tasks"
    ];

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
