{ pkgs, ... }:
{
  programs = {
    opencode = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then null else pkgs.opencode;
      settings = {
        theme = "catppuccin";
        share = "disabled";
        username = "mholtzscher";
        keybinds = {
          "session_child_cycle" = "shift+right";
          "session_child_cycle_reverse" = "shift+left";
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
        };
        command = {
          "diff-review" = {
            description = "Perform a comprehensive code review of recent changes";
            agent = "build";
            template = "{file:${../files/opencode/commands/diff-review.md}}";
          };
          "commit" = {
            description = "Analyze staged changes and create a conventional commit";
            agent = "general";
            subtask = true;
            template = "{file:${../files/opencode/commands/conventional-commit.md}}";
          };
        };
        agent = {
          "code-reviewer" = {
            disable = true;
            description = "Reviews code for best practices and potential issues";
            mode = "subagent";
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
            disable = true;
            mode = "subagent";
            description = "Master software architect specializing in modern architecture patterns, clean architecture, microservices, event-driven systems, and DDD. Reviews system designs and code changes for architectural integrity, scalability, and maintainability. Use PROACTIVELY for architectural decisions.";
            prompt = "{file:${../files/opencode/agents/architect-review.md}}";
          };
          research = {
            disable = true;
            mode = "subagent";
            description = "Enterprise Research Assistant named \"Claudette\" that autonomously conducts comprehensive research with rigorous source verification and synthesis.";
            prompt = "{file:${../files/opencode/agents/research.md}}";
          };
          lookup = {
            disable = false;
            model = "opencode/claude-haiku-4-5";
            mode = "subagent";
            permission = {
              edit = "deny";
              write = "deny";
            };
            tools = {
              "gh_grep*" = true;
              "exa*" = true;
            };
            description = "This agent excels at researching and locating information. It's optimized for finding where specific code elements are defined or used, reading and interpreting documentation, researching technical details, and retrieving code examples that demonstrate best practices or specific APls. It's also great at maintaining and leveraging context, helping the primary agent quickly surface relevant information from large codebases, docs, or external sources.";
            prompt = "After conducting your research, summarize the key findings clearly and concisely. Include only the most relevant code examples, file names, and sources as needed.";
          };
        };
        tools = {
          "gh_grep*" = false;
          "exa*" = false;
        };
        mcp = {
          beads = {
            type = "local";
            command = [ "beads-mcp" ];
            enabled = true;
          };
          gh_grep = {
            type = "remote";
            url = "https://mcp.grep.app/";
            enabled = true;
          };
          exa = {
            type = "local";
            command = [
              "bunx"
              "exa-mcp-server"
            ];
            enabled = true;
          };
        };
      };
    };
  };
}
