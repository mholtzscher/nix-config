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

      mattpocock = {
        input = "mattpocock-skills";
        idPrefix = "mattpocock";
        filter.maxDepth = 1;
      };

      vercel = {
        input = "vercel-agent-browser";
        subdir = "skills";
      };

      nicobailon = {
        input = "nicobailon-visual-explainer";
        subdir = "plugins";
        idPrefix = "nicobailon";
        filter.maxDepth = 1;
      };
    };

    skills.enable = [
      "atlassian-api"
      "conventional-commits"
      # "addyosmani/api-and-interface-design"
      # "addyosmani/browser-testing-with-devtools"
      # "addyosmani/ci-cd-and-automation"
      # "addyosmani/code-review-and-quality"
      # "addyosmani/code-simplification"
      # "addyosmani/context-engineering"
      # "addyosmani/debugging-and-error-recovery"
      # "addyosmani/deprecation-and-migration"
      # "addyosmani/documentation-and-adrs"
      # "addyosmani/frontend-ui-engineering"
      # "addyosmani/git-workflow-and-versioning"
      # "addyosmani/idea-refine"
      # "addyosmani/incremental-implementation"
      # "addyosmani/performance-optimization"
      # "addyosmani/planning-and-task-breakdown"
      # "addyosmani/security-and-hardening"
      # "addyosmani/shipping-and-launch"
      # "addyosmani/source-driven-development"
      # "addyosmani/spec-driven-development"
      # "addyosmani/test-driven-development"
      # "addyosmani/using-agent-skills"
      # "gradle"
      # "index-knowledge"
      # "librarian"
      # "mermaid"
      "anthropic/frontend-design"
      "anthropic/skill-creator"
      "cloudflare/agents-sdk"
      "cloudflare/cloudflare"
      "cloudflare/durable-objects"
      "cloudflare/sandbox-sdk"
      "cloudflare/web-perf"
      "cloudflare/workers-best-practices"
      "cloudflare/wrangler"
      "agent-browser"
      "spec-planner"
      "nicobailon/visual-explainer"
      # "mattpocock/caveman"
      # "mattpocock/design-an-interface"
      # "mattpocock/domain-model"
      # "mattpocock/edit-article"
      # "mattpocock/git-guardrails-claude-code"
      # "mattpocock/github-triage"
      # "mattpocock/grill-me"
      # "mattpocock/improve-codebase-architecture"
      # "mattpocock/migrate-to-shoehorn"
      # "mattpocock/obsidian-vault"
      # "mattpocock/qa"
      # "mattpocock/request-refactor-plan"
      # "mattpocock/scaffold-exercises"
      # "mattpocock/setup-pre-commit"
      # "mattpocock/tdd"
      # "mattpocock/to-issues"
      # "mattpocock/to-prd"
      # "mattpocock/triage-issue"
      # "mattpocock/ubiquitous-language"
      # "mattpocock/write-a-skill"
      # "mattpocock/zoom-out"
      "zellij-tasks"
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
