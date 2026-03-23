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
    "gradle"
    "index-knowledge"
    "mermaid"
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

  home.activation = lib.mkIf (!isWork) {
    piAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dst="${config.home.homeDirectory}/.pi/agent/auth.json"
      run mkdir -p "$(dirname "$dst")"
      run install -m 600 ${./files/pi/auth.json} "$dst"
    '';
  };

  home.file = lib.optionalAttrs (!isWork) (
    skillFiles
    // {
      ".pi/agent/settings.json".source = ./files/pi/settings.json;

      ".pi/agent/themes" = {
        source = ./files/pi/themes;
      };

      ".pi/agent/prompts" = {
        source = ./files/pi/prompts;
        recursive = true;
      };

      ".pi/agent/extensions" = {
        source = ./files/pi/extensions;
        recursive = true;
      };
    }
  );
}
