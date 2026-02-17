{
  pkgs,
  lib,
  inputs,
  isWork,
  config,
  ...
}:
{
  home.sessionVariables = lib.mkIf (!isWork) {
    OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
  };

  home.file = lib.mkIf (!isWork) {
    "${config.xdg.configHome}/opencode/skills" = {
      source = ../files/opencode/skills;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/agents" = {
      source = ../files/opencode/agents;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/commands" = {
      source = ../files/opencode/commands;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/AGENTS.md".source = ../files/opencode/AGENTS.md;
  };

  programs = {
    opencode = {
      enable = !isWork;
      package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        # share = "disabled";
        username = "mholtzscher";
        plugin = [ "@mohak34/opencode-notifier" ];
        permission = {
          bash = {
            "*" = "ask";
            "just *" = "allow";
            "ast-grep *" = "allow";
            "awk *" = "allow";
            "basename *" = "allow";
            "biome *" = "allow";
            "bun *" = "allow";
            "cargo *" = "allow";
            "cat *" = "allow";
            "cloc *" = "allow";
            "cp *" = "allow";
            "date *" = "allow";
            "diff *" = "allow";
            "dirname *" = "allow";
            "doggo *" = "allow";
            "dot *" = "allow";
            "du *" = "allow";
            "echo *" = "allow";
            "fd *" = "allow";
            "file *" = "allow";
            "find *" = "allow";
            "fnm *" = "allow";
            "fzf *" = "allow";
            "gh *" = "allow";
            "gh * approve*" = "ask";
            "gh * close*" = "ask";
            "gh * comment*" = "ask";
            "gh * create*" = "ask";
            "gh * delete*" = "ask";
            "gh * edit*" = "ask";
            "gh * merge*" = "ask";
            "gh * reopen*" = "ask";
            "gh * review*" = "ask";
            "gh repo clone*" = "allow";
            "git *" = "allow";
            "git push*" = "ask";
            "glab *" = "allow";
            "glab * approve*" = "ask";
            "glab * close*" = "ask";
            "glab * comment*" = "ask";
            "glab * create*" = "ask";
            "glab * delete*" = "ask";
            "glab * edit*" = "ask";
            "glab * merge*" = "ask";
            "glab * reopen*" = "ask";
            "glab * review*" = "ask";
            "glab repo clone*" = "allow";
            "go *" = "allow";
            "grep *" = "allow";
            "gsed *" = "allow";
            "gunzip *" = "allow";
            "gzip *" = "allow";
            "head *" = "allow";
            "hostname" = "allow";
            "id" = "allow";
            "jj *" = "allow";
            "jj git push*" = "ask";
            "jj gp*" = "ask";
            "jq *" = "allow";
            "ls *" = "allow";
            "make *" = "allow";
            "mkdir *" = "allow";
            "mv *" = "allow";
            "npm *" = "allow";
            "open *" = "allow";
            "pbcopy" = "allow";
            "pbpaste" = "allow";
            "pnpm *" = "allow";
            "prettier *" = "allow";
            "printf *" = "allow";
            "pwd" = "allow";
            "readlink *" = "allow";
            "realpath *" = "allow";
            "rg *" = "allow";
            "sed *" = "allow";
            "shellcheck *" = "allow";
            "sort *" = "allow";
            "stat *" = "allow";
            "stow *" = "allow";
            "stylua *" = "allow";
            "tail *" = "allow";
            "tar *" = "allow";
            "tee *" = "allow";
            "touch *" = "allow";
            "tr *" = "allow";
            "tree *" = "allow";
            "true" = "allow";
            "tsc *" = "allow";
            "turbo *" = "allow";
            "uname *" = "allow";
            "uniq *" = "allow";
            "unzip *" = "allow";
            "vite *" = "allow";
            "vitest *" = "allow";
            "wc *" = "allow";
            "which *" = "allow";
            "whoami" = "allow";
            "xargs *" = "ask";
            "yarn *" = "allow";
            "z *" = "allow";
            "zip *" = "allow";
            "zoxide *" = "allow";
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
          webfetch = "ask";
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
            enabled = true;
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
            enabled = true;
          };
        };
      };
    };
  };
}
