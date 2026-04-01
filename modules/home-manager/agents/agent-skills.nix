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

      vercel = {
        input = "vercel-agent-browser";
        subdir = "skills";
      };
    };

    skills.enable = [
      "atlassian-api"
      "conventional-commits"
      "gradle"
      "index-knowledge"
      # "librarian"
      # "mermaid"
      "anthropic/frontend-design"
      "anthropic/skill-creator"
      "agent-browser"
      "spec-planner"
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
