{
  pkgs,
  lib,
  inputs,
  isWork,
  config,
  ...
}:
let
  mkPathAsset = targets: path: {
    inherit targets;
    source = {
      type = "path";
      inherit path;
    };
  };

  opencodeTargets = [ "opencode" ];
  piTargets = [ "pi" ];
  sharedSkillTargets = [
    "opencode"
    "pi"
  ];
in
{
  # home.sessionVariables = lib.mkIf (!isWork) {
  home.sessionVariables = {
    OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
    # OPENCODE_EXPERIMENTAL = "true";
  };

  # home.file = lib.mkIf (!isWork) {
  home.file = {
    "${config.xdg.configHome}/opencode/plugins" = {
      source = ../files/opencode/plugins;
      recursive = true;
    };
  };

  # Use activation copy (not HM symlink) so opencode tools deps resolve/load correctly.
  # home.activation.opencodeTools = lib.mkIf (!isWork) (
  # home.activation.opencodeTools = (
  #   lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #     dst="${config.xdg.configHome}/opencode/tools"
  #     src="${../files/opencode/tools}"
  #
  #     rm -rf "$dst"
  #     mkdir -p "$dst"
  #     cp -R "$src"/. "$dst"/
  #   ''
  # );

  programs = {
    "agent-assets" = {
      enable = true;
      targets = {
        opencode.enable = true;
        pi.enable = true;
      };

      docs."AGENTS.md" = mkPathAsset sharedSkillTargets ../files/opencode/AGENTS.md;

      agents = {
        "code-reviewer" = mkPathAsset opencodeTargets ../files/opencode/agents/code-reviewer.md;
        librarian = mkPathAsset opencodeTargets ../files/opencode/agents/librarian.md;
        mermaid = mkPathAsset opencodeTargets ../files/opencode/agents/mermaid.md;
        oracle = mkPathAsset opencodeTargets ../files/opencode/agents/oracle.md;
        sensei = mkPathAsset opencodeTargets ../files/opencode/agents/sensei.md;
      };

      commands = {
        "build-skill" = mkPathAsset opencodeTargets ../files/opencode/commands/build-skill.md;
        "diff-review" = mkPathAsset opencodeTargets ../files/opencode/commands/diff-review.md;
        "index-knowledge" = mkPathAsset opencodeTargets ../files/opencode/commands/index-knowledge.md;
        "plan-spec" = mkPathAsset opencodeTargets ../files/opencode/commands/plan-spec.md;
        slop = mkPathAsset opencodeTargets ../files/opencode/commands/slop.md;
        yeet = mkPathAsset opencodeTargets ../files/opencode/commands/yeet.md;
      };

      skills = {
        "atlas-cli" = mkPathAsset sharedSkillTargets ../files/opencode/skills/atlas-cli;
        "build-skill" = mkPathAsset sharedSkillTargets ../files/opencode/skills/build-skill;
        "conventional-commit" = mkPathAsset piTargets ../files/opencode/skills/conventional-commits;
        "conventional-commits" = mkPathAsset opencodeTargets ../files/opencode/skills/conventional-commits;
        "index-knowledge" = mkPathAsset sharedSkillTargets ../files/opencode/skills/index-knowledge;
        librarian = mkPathAsset sharedSkillTargets ../files/opencode/skills/librarian;
        "spec-planner" = mkPathAsset sharedSkillTargets ../files/opencode/skills/spec-planner;
      };
    };

    opencode = {
      enable = !isWork;
      package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        # share = "disabled";
        username = "mholtzscher";
        agent.plan = {
          model = "openai/gpt-5.4";
          reasoningEffort = "high";
        };
        # agent.explore.model = "openai/gpt-5.3-codex-spark";
        agent.explore.model = "opencode/gemini-3-flash";
        permission = {
          bash = {
            #   "*" = "ask";
            #   "nix flake check" = "allow";
            #   "just *" = "allow";
            #   "awk *" = "allow";
            #   "basename *" = "allow";
            #   "biome *" = "allow";
            #   "bun *" = "allow";
            #   "cargo *" = "allow";
            #   "cat *" = "allow";
            #   "cloc *" = "allow";
            #   "cp *" = "allow";
            #   "date *" = "allow";
            #   "diff *" = "allow";
            #   "dirname *" = "allow";
            #   "doggo *" = "allow";
            #   "dot *" = "allow";
            #   "du *" = "allow";
            #   "echo *" = "allow";
            #   "fd *" = "allow";
            #   "file *" = "allow";
            #   "find *" = "allow";
            #   "fnm *" = "allow";
            #   "fzf *" = "allow";
            #   "gh *" = "allow";
            #   "gh * approve*" = "ask";
            #   "gh * close*" = "ask";
            #   "gh * comment*" = "ask";
            #   "gh * create*" = "allow";
            #   "gh * delete*" = "ask";
            #   "gh * edit*" = "ask";
            #   "gh * merge*" = "ask";
            #   "gh * reopen*" = "ask";
            #   "gh * review*" = "ask";
            #   "gh repo clone*" = "allow";
            #   "git *" = "allow";
            #   "git push*" = "ask";
            #   "glab *" = "allow";
            #   "glab * approve*" = "ask";
            #   "glab * close*" = "ask";
            #   "glab * comment*" = "ask";
            #   "glab * create*" = "ask";
            #   "glab * delete*" = "ask";
            #   "glab * edit*" = "ask";
            #   "glab * merge*" = "ask";
            #   "glab * reopen*" = "ask";
            #   "glab * review*" = "ask";
            #   "glab repo clone*" = "allow";
            #   "go *" = "allow";
            #   "grep *" = "allow";
            #   "gsed *" = "allow";
            #   "gunzip *" = "allow";
            #   "gzip *" = "allow";
            #   "head *" = "allow";
            #   "hostname" = "allow";
            #   "id" = "allow";
            #   "jj *" = "allow";
            #   "jj git push*" = "ask";
            #   "jj gp*" = "ask";
            #   "jq *" = "allow";
            #   "ls *" = "allow";
            #   "make *" = "allow";
            #   "mkdir *" = "allow";
            #   "mv *" = "allow";
            #   "npm *" = "allow";
            #   "open *" = "allow";
            #   "pbcopy" = "allow";
            #   "pbpaste" = "allow";
            #   "pnpm *" = "allow";
            #   "prettier *" = "allow";
            #   "printf *" = "allow";
            #   "pwd" = "allow";
            #   "readlink *" = "allow";
            #   "realpath *" = "allow";
            #   "rg *" = "allow";
            #   "sed *" = "allow";
            #   "shellcheck *" = "allow";
            #   "sort *" = "allow";
            #   "stat *" = "allow";
            #   "stow *" = "allow";
            #   "stylua *" = "allow";
            #   "tail *" = "allow";
            #   "tar *" = "allow";
            #   "tee *" = "allow";
            #   "touch *" = "allow";
            #   "tr *" = "allow";
            #   "tree *" = "allow";
            #   "true" = "allow";
            #   "tsc *" = "allow";
            #   "turbo *" = "allow";
            #   "uname *" = "allow";
            #   "uniq *" = "allow";
            #   "unzip *" = "allow";
            #   "vite *" = "allow";
            #   "vitest *" = "allow";
            #   "wc *" = "allow";
            #   "which *" = "allow";
            #   "whoami" = "allow";
            #   "xargs *" = "ask";
            #   "yarn *" = "allow";
            #   "z *" = "allow";
            #   "zip *" = "allow";
            #   "zoxide *" = "allow";
          };
          external_directory = {
            "~/go/pkg/mod/**" = "allow";
            "~/.cache/go-build/**" = "allow";
            "~/Library/Caches/go-build/**" = "allow";
          };
          edit = {
            "~/go/pkg/mod/**" = "deny";
            "~/.cache/go-build/**" = "deny";
            "~/Library/Caches/go-build/**" = "deny";
          };
          read = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
            "*.envrc" = "deny";
            "secrets/*" = "deny";
            ".dev.vars" = "ask";
            "~/.local/share/opencode/mcp-auth.json" = "deny";
          };
          # webfetch = "ask";
        };
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

        formatter = {
          nix = {
            command = [
              "nixfmt"
              "$FILE"
            ];
            extensions = [ ".nix" ];
          };
        };
        tools = {
          # "gh_grep*" = false;
          # "exa*" = false;
        };
        mcp = {
          gh_grep = {
            enabled = !isWork;
            type = "remote";
            url = "https://mcp.grep.app/";
          };
          opensrc = {
            type = "local";
            command = [
              "npx"
              "-y"
              "opensrc-mcp"
            ];
            enabled = !isWork;
          };
        };
      };
    };
  };
}
