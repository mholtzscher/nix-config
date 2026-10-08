{ pkgs, inputs, ... }:
{
  # Lazygit now expects authorColors inside gui.theme. Migrate the pinned
  # Catppuccin source at build time, since runtime migration cannot write to /nix/store.
  catppuccin.sources.lazygit =
    ((import inputs.catppuccin { inherit pkgs; }).packages.lazygit).overrideAttrs
      (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.yq-go ];
        postInstall = (old.postInstall or "") + ''
          while IFS= read -r -d "" theme; do
            if yq -e '.gui | has("authorColors")' "$theme" >/dev/null; then
              yq -i '.gui.theme.authorColors = .gui.authorColors | del(.gui.authorColors)' "$theme"
            fi
          done < <(find "$out" -name '*.yml' -print0)
        '';
      });

  programs = {
    lazygit = {
      enable = true;
      settings = {
        commitLength = {
          show = false;
        };

        gui = {
          nerdFontsVersion = "3";
        };

        customCommands = [
          {
            key = "O";
            description = "Open Pull Request with GitHub CLI";
            context = "global";
            command = "gh pr create -df; gh pr view --web";
            loadingText = "Creating Pull Request";
          }
          {
            key = "C";
            description = "AI Commit - Generate conventional commit (with confirmation)";
            context = "files";
            command = "nu --login -c 'ai_commit'";
            output = "terminal";
            loadingText = "Generating commit message with AI...";
          }
          {
            key = "<c-c>";
            description = "AI Commit - Auto-commit without confirmation";
            context = "files";
            command = "nu --login -c 'ai_commit --yes'";
            output = "terminal";
            loadingText = "Generating and committing with AI...";
          }
        ];
      };
    };
  };
}
