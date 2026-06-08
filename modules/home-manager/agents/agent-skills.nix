{
  config,
  lib,
  inputs,
  isWork,
  ...
}:
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

      roerohan = {
        input = "roerohan-skills";
        idPrefix = "roerohan";
      };

      vercel = {
        input = "vercel-agent-browser";
        subdir = "skills";
        idPrefix = "vercel";
      };

      hunk = {
        input = "hunk";
        subdir = "skills";
        idPrefix = "hunk";
      };
    };

    skills.enable = [
      "anthropic/frontend-design"
      "anthropic/skill-creator"
      "mattpocock/grill-with-docs"
      "mattpocock/improve-codebase-architecture"
      "mattpocock/tdd"
      "mattpocock/teach"
      "roerohan/diff-walkthrough"
      # "mholtzscher/atlassian-api"
      "mholtzscher/conventional-commits"
      "mholtzscher/spec-planner"
      "vercel/agent-browser"
      "hunk/hunk-review"
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
      "mholtzscher/zellij-tasks"
    ];

    targets.pi = {
      enable = !isWork;
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
