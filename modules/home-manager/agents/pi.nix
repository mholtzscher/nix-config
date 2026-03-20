{
  pkgs,
  lib,
  inputs,
  isWork,
  config,
  ...
}:
let
  skillSources = import ./files/skills;

  # Selectively load skills for pi agent
  # Add skill names here to enable them
  piSkills = [
    # "atlas-cli"
    "build-skill"
    "conventional-commits"
    "index-knowledge"
    # "librarian"
    "spec-planner"
  ];

  # Generate file mappings for selected skills
  mkSkillFiles = skillName: {
    ".pi/agent/skills/${skillName}" = {
      source = skillSources.${skillName};
      recursive = true;
    };
  };

  skillFiles = lib.foldl' (acc: skill: acc // mkSkillFiles skill) { } piSkills;
in
{
  home.packages = lib.optionals (!isWork) [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  home.file = lib.optionalAttrs (!isWork) (
    skillFiles
    // {
      ".pi/agent/settings.json".source = ./files/pi/settings.json;
    }
  );
}
