{
  ...
}:
{
  programs = {
    starship = {
      enable = true;
      settings = {
        format = "$username$hostname$directory$git_branch$git_state$git_status$line_break$character";
        right_format = "\${env_var.GITHUB_TOKEN}\${env_var.GH_TOKEN}\${env_var.GITHUB_PAT}$aws$mise$direnv";

        add_newline = false;

        fill = {
          symbol = " ";
        };

        directory = {
          style = "blue";
        };

        env_var.GITHUB_TOKEN = {
          variable = "GITHUB_TOKEN";
          format = "[󰊤 TOKEN]($style) ";
          style = "dimmed blue";
        };

        env_var.GH_TOKEN = {
          variable = "GH_TOKEN";
          format = "[󰊤 GH]($style) ";
          style = "dimmed green";
        };

        env_var.GITHUB_PAT = {
          variable = "GITHUB_PAT";
          format = "[󰊤 PAT]($style) ";
          style = "dimmed purple";
        };

        direnv = {
          disabled = false;
          style = "dimmed blue";
        };

        character = {
          success_symbol = "[❯](purple)";
          error_symbol = "[❯](red)";
          vimcmd_symbol = "[❮](green)";
        };

        git_branch = {
          format = "[$branch]($style)";
          style = "bright-black";
        };

        git_status = {
          format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
          style = "cyan";
          conflicted = "​";
          untracked = "​";
          modified = "​";
          staged = "​";
          renamed = "​";
          deleted = "​";
          stashed = "≡";
        };

        git_state = {
          format = ''\([$state( $progress_current/$progress_total)]($style)\) '';
          style = "bright-black";
        };

        aws = {
          # format = " [aws](italic) [$profile $region]($style)";
          symbol = "󰅟 ";
          format = "[$symbol$profile $region]($style) ";
          style = "dimmed yellow";
        };

        mise = {
          symbol = "🔨 ";
          format = "[$symbol$health]($style) ";
          style = "bold purple";
          disabled = false;
          detect_files = [ ".tool-versions" ];
        };

      };
    };
  };
}
