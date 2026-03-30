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

    sources.local = {
      path = ./files/skills;
      filter.maxDepth = 1;
    };

    skills.enable = [
      "atlassian-api"
      # "build-skill"
      "conventional-commits"
      "gradle"
      "index-knowledge"
      # "librarian"
      # "mermaid"
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
