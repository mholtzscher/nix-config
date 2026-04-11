{
  config,
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
        filter.maxDepth = 1;
      };

      anthropic = {
        input = "anthropic-skills";
        subdir = "skills";
        idPrefix = "anthropic";
      };

      cloudflare = {
        input = "cloudflare-skills";
        subdir = "skills";
        idPrefix = "cloudflare";
        filter.maxDepth = 1;
      };

      addyosmani = {
        input = "addyosmani-agent-skills";
        subdir = "skills";
        idPrefix = "addyosmani";
        filter.maxDepth = 1;
      };

      vercel = {
        input = "vercel-agent-browser";
        subdir = "skills";
      };
    };

    skills.enable = [
      "atlassian-api"
      "conventional-commits"
      "addyosmani/api-and-interface-design"
      "addyosmani/browser-testing-with-devtools"
      "addyosmani/ci-cd-and-automation"
      "addyosmani/code-review-and-quality"
      "addyosmani/code-simplification"
      "addyosmani/context-engineering"
      "addyosmani/debugging-and-error-recovery"
      "addyosmani/deprecation-and-migration"
      "addyosmani/documentation-and-adrs"
      "addyosmani/frontend-ui-engineering"
      "addyosmani/git-workflow-and-versioning"
      "addyosmani/idea-refine"
      "addyosmani/incremental-implementation"
      "addyosmani/performance-optimization"
      "addyosmani/planning-and-task-breakdown"
      "addyosmani/security-and-hardening"
      "addyosmani/shipping-and-launch"
      "addyosmani/source-driven-development"
      "addyosmani/spec-driven-development"
      "addyosmani/test-driven-development"
      "addyosmani/using-agent-skills"
      # "gradle"
      # "index-knowledge"
      # "librarian"
      # "mermaid"
      "anthropic/frontend-design"
      "anthropic/skill-creator"
      # "cloudflare/agents-sdk"
      # "cloudflare/building-ai-agent-on-cloudflare"
      # "cloudflare/building-mcp-server-on-cloudflare"
      "cloudflare/cloudflare"
      # "cloudflare/durable-objects"
      # "cloudflare/sandbox-sdk"
      # "cloudflare/web-perf"
      "cloudflare/workers-best-practices"
      "cloudflare/wrangler"
      "agent-browser"
      # "spec-planner"
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
