{ pkgs, ... }:
{
  programs = {
    opencode = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then null else pkgs.opencode;
      settings = {
        theme = "system";
        # model = "anthropic/claude-haiku-4.5";
        share = "disabled";
        username = "mholtzscher";
        keybinds = {
          session_child_cycle = "shift+right";
          session_child_cycle_reverse = "shift+left";
        };
        lsp = {
          nushell = {
            command = [
              "nu"
              "--lsp"
            ];
            extensions = [ ".nu" ];
          };
          nix = {
            command = [
              "nil"
            ];
            extensions = [ ".nix" ];
          };
          # kotlin = {
          #   command = [
          #     "kotlin-lsp"
          #   ];
          #   extensions = [ ".kt" ];
          # };
        };
        command = {
          "diff-review" = {
            description = "Perform a comprehensive code review of recent changes";
            agent = "build";
            # model = "github-copilot/claude-sonnet-4";
            template = "{file:${../files/opencode/commands/diff-review.md}}";
          };
          "commit" = {
            description = "Analyze staged changes and create a conventional commit";
            agent = "general";
            subtask = true;
            # model = "anthropic/claude-sonnet-4-5-20250929";
            template = "{file:${../files/opencode/commands/commit.md}}";
          };
        };
        agent = {
          "code-reviewer" = {
            description = "Reviews code for best practices and potential issues";
            mode = "subagent";
            # model = "anthropic/claude-sonnet-4-20250514";
            prompt = "You are a code reviewer. Focus on security, performance, and maintainability.";
            tools = {
              write = false;
              edit = false;
            };
          };
          mermaid = {
            mode = "subagent";
            description = "Create Mermaid diagrams for flowcharts, sequences, ERDs, and architectures. Masters syntax for all diagram types and styling. Use PROACTIVELY for visual documentation, system diagrams, or process flows.";
            prompt = "{file:${../files/opencode/agents/mermaid.md}}";
          };
          "architect-review" = {
            mode = "subagent";
            description = "Master software architect specializing in modern architecture patterns, clean architecture, microservices, event-driven systems, and DDD. Reviews system designs and code changes for architectural integrity, scalability, and maintainability. Use PROACTIVELY for architectural decisions.";
            prompt = "{file:${../files/opencode/agents/architect-review.md}}";
          };
          research = {
            mode = "subagent";
            description = "Enterprise Research Assistant named \"Claudette\" that autonomously conducts comprehensive research with rigorous source verification and synthesis.";
            prompt = "{file:${../files/opencode/agents/research.md}}";
          };
          # claudette = {
          #   mode = "primary";
          #   description = "Claudette Coding Agent v5.2.1 (Optimized for Autonomous Execution)";
          #   prompt = "{file:${../files/opencode/agents/claudette.md}}";
          # };

          # "plankton" = {
          #   description = "Plan mode agent for creating structured implementation plans";
          #   mode = "primary";
          #   prompt = "{file:${../files/opencode/agents/plankton.md}}";
          #   tools = {
          #     write = false;
          #     edit = false;
          #     bash = false;
          #     todowrite = true;
          #     todoread = true;
          #   };
          # };
        };
      };
    };
  };
}
