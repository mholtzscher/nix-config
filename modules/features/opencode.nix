# OpenCode
{ config, lib, ... }:
let
  cfg = config.myFeatures.opencode;
in
{
  options.myFeatures.opencode = {
    enable = lib.mkEnableOption "opencode configuration" // {
      default = true;
      description = "Enable opencode (disabled on work hosts)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.opencode =
      {
        pkgs,
        inputs,
        isWork ? false,
        config,
        ...
      }:
      {
        home.file."${config.xdg.configHome}/opencode/skill/conventional-commit/SKILL.md".source =
          ../../files/opencode/skills/conventional-commit.md;

        programs.opencode = {
          enable = !isWork;
          package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
          settings = {
            username = "mholtzscher";
            keybinds = {
              session_child_cycle = "shift+right";
              session_child_cycle_reverse = "shift+left";
            };

            lsp = {
              nushell = {
                command = [ "nu" "--lsp" ];
                extensions = [ ".nu" ];
              };
              nix = {
                command = [ "nil" ];
                extensions = [ ".nix" ];
              };
            };

            command = {
              diff-review = {
                description = "Perform a comprehensive code review of recent changes";
                agent = "build";
                template = "{file:${../../files/opencode/commands/diff-review.md}}";
              };
              slop = {
                description = "Remove AI code slop";
                template = ''
                  Check the diff against main, and remove all AI generated slop introduced in this branch.

                  This includes:

                  Extra comments that a human wouldn't add or is inconsistent with the rest of the file
                  Extra defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted / validated codepaths)
                  Casts to any to get around type issues
                  Any other style that is inconsistent with the file

                  Report at the end with only a 1-3 sentence summary of what you changed
                '';
              };
            };

            agent = {
              mermaid = {
                mode = "subagent";
                description = "Create Mermaid diagrams for flowcharts, sequences, ERDs, and architectures. Masters syntax for all diagram types and styling. Use PROACTIVELY for visual documentation, system diagrams, or process flows.";
                prompt = "{file:${../../files/opencode/agents/mermaid.md}}";
              };
              architect-review = {
                mode = "subagent";
                description = "Master software architect specializing in modern architecture patterns, clean architecture, microservices, event-driven systems, and DDD. Reviews system designs and code changes for architectural integrity, scalability, and maintainability. Use PROACTIVELY for architectural decisions.";
                prompt = "{file:${../../files/opencode/agents/architect-review.md}}";
              };
              research = {
                mode = "subagent";
                description = "Enterprise Research Assistant named \"Claudette\" that autonomously conducts comprehensive research with rigorous source verification and synthesis.";
                prompt = "{file:${../../files/opencode/agents/research.md}}";
              };
              lookup = {
                model = "opencode/claude-haiku-4-5";
                mode = "subagent";
                permission.edit = "deny";
                description = "This agent excels at researching and locating information. It's optimized for finding where specific code elements are defined or used, reading and interpreting documentation, researching technical details, and retrieving code examples that demonstrate best practices or specific APls. It's also great at maintaining and leveraging context, helping the primary agent quickly surface relevant information from large codebases, docs, or external sources.";
                prompt = "After conducting your research, summarize the key findings clearly and concisely. Include only the most relevant code examples, file names, and sources as needed. Store research in research/<topic>/<doc>.md folder structure.";
              };
            };

            formatter.nix = {
              command = [ "nixfmt" "$FILE" ];
              extensions = [ ".nix" ];
            };
          };
        };
      };
  };
}
