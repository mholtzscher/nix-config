{ pkgs, ... }:
let
  brew_setup = "/opt/homebrew/bin/brew shellenv 2>/dev/null | source || true";
  sharedAliases = import ../shared-aliases.nix;
in
{
  # TODO: remove fish and use nushell everywhere else
  programs = {
    fish = {
      enable = true;
      shellAbbrs = sharedAliases.shellAliases // { };

      interactiveShellInit = ''
          # ${brew_setup}

          # Enable fish vi mode
          set -g fish_key_bindings fish_vi_key_bindings

          # set -x GOPATH (go env GOPATH)
          # set -x PATH $PATH (go env GOPATH)/bin
          set -x GOPATH $HOME/go
          set -x PATH $PATH $HOME/go/bin
          
          # Local bin directory
          set -x PATH $PATH $HOME/.local/bin

          # ASDF configuration code
          if test -z $ASDF_DATA_DIR
              set _asdf_shims "$HOME/.asdf/shims"
          else
              set _asdf_shims "$ASDF_DATA_DIR/shims"
          end

          # Do not use fish_add_path (added in Fish 3.2) because it
          # potentially changes the order of items in PATH
          if not contains $_asdf_shims $PATH
              set -gx --prepend PATH $_asdf_shims
          end
          set --erase _asdf_shims

          # Kubernetes config setup
          for kubeconfigFile in (fd -e yml -e yaml . "$HOME/.kube")
              set -gx KUBECONFIG "$kubeconfigFile:$KUBECONFIG"
          end

          # FZF catppuccin theme
          # set -Ux FZF_DEFAULT_OPTS "\
          # --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
          # --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
          # --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
          # --color=selected-bg:#45475a \
          # --multi"

          # FZF tokyonight_night theme
          set -Ux FZF_DEFAULT_OPTS " \
          --highlight-line \
          --info=inline-right \
          --ansi \
          --layout=reverse \
          --border=none \
          --color=bg+:#283457 \
          --color=bg:#16161e \
          --color=border:#27a1b9 \
          --color=fg:#c0caf5 \
          --color=gutter:#16161e \
          --color=header:#ff9e64 \
          --color=hl+:#2ac3de \
          --color=hl:#2ac3de \
          --color=info:#545c7e \
          --color=marker:#ff007c \
          --color=pointer:#ff007c \
          --color=prompt:#2ac3de \
          --color=query:#c0caf5:regular \
          --color=scrollbar:#27a1b9 \
          --color=separator:#ff9e64 \
          --color=spinner:#ff007c \
        "

        # Fish TokyoNight Color Palette
        set -l foreground c0caf5
        set -l selection 283457
        set -l comment 565f89
        set -l red f7768e
        set -l orange ff9e64
        set -l yellow e0af68
        set -l green 9ece6a
        set -l purple 9d7cd8
        set -l cyan 7dcfff
        set -l pink bb9af7

        # Syntax Highlighting Colors
        set -g fish_color_normal $foreground
        set -g fish_color_command $cyan
        set -g fish_color_keyword $pink
        set -g fish_color_quote $yellow
        set -g fish_color_redirection $foreground
        set -g fish_color_end $orange
        set -g fish_color_option $pink
        set -g fish_color_error $red
        set -g fish_color_param $purple
        set -g fish_color_comment $comment
        set -g fish_color_selection --background=$selection
        set -g fish_color_search_match --background=$selection
        set -g fish_color_operator $green
        set -g fish_color_escape $pink
        set -g fish_color_autosuggestion $comment

        # Completion Pager Colors
        set -g fish_pager_color_progress $comment
        set -g fish_pager_color_prefix $cyan
        set -g fish_pager_color_completion $foreground
        set -g fish_pager_color_description $comment
        set -g fish_pager_color_selected_background --background=$selection
      '';

      functions = {

        cloudcache = {
          body = builtins.readFile ../files/fish/functions/cloudcache.fish;
          description = "Clear Cloudflare zone cache";
        };

        pat = {
          body = ''set -gx GITHUB_PAT (op read "op://Personal/Github/paytient-pat")'';
          description = "Set the GITHUB_PAT environment variable";
        };

        __ssh_tunnel = {
          body = builtins.readFile ../files/fish/functions/__ssh_tunnel.fish;
          description = "Create an SSH tunnel";
        };

        aws_change_profile = {
          body = builtins.readFile ../files/fish/functions/aws_change_profile.fish;
          description = "Change the AWS profile and login to SSO";
        };

        aws_ecr_login = {
          body = "aws ecr get-login-password | docker login --username AWS --password-stdin 188442536245.dkr.ecr.us-west-2.amazonaws.com";
          description = "Login to AWS ECR";
        };

        aws_export_envs = {
          body = "export (aws configure export-credentials --profile $AWS_PROFILE --format env-no-export )";
          description = "Export AWS credentials as environment variables";
        };

        awslocal = {
          body = "env AWS_PROFILE=localstack aws --endpoint-url=http://localhost.localstack.cloud:4566 $argv";
          description = "Run AWS CLI commands against LocalStack";
        };

        aws_logout = {
          body = builtins.readFile ../files/fish/functions/aws_logout.fish;
          description = "logout from AWS SSO";
        };

        build = {
          body = "gradle build --parallel";
          description = "build project";
        };

        cacheclear = {
          body = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder $argv";
          description = " clear dns cache";
        };

        chad = {
          body = builtins.readFile ../files/fish/functions/chad.fish;
          description = "chezmoi add with fzf";
        };

        chf = {
          body = builtins.readFile ../files/fish/functions/chf.fish;
          description = "chezmoi forget with fzf";
        };

        clean = {
          body = "git clean -Xdf $argv";
          description = "clean untracked files";
        };

        fmt = {
          body = builtins.readFile ../files/fish/functions/fmt.fish;
          description = "Run the formatter for the current project";
        };

        ghpr = {
          body = ''
            gh pr create -df
            gh pr view --web
          '';
          description = "Create a pull request on GitHub";
        };

        gitignore = {
          body = "curl -sL https://www.gitignore.io/api/$argv";
          description = "get gitgnore for language";
        };

        gradle = {
          body = builtins.readFile ../files/fish/functions/gradle.fish;
          description = "swaps ./gradlew for gradle";
          wraps = "./gradlew";

        };

        ifactive = {
          body = builtins.readFile ../files/fish/functions/ifactive.fish;
          description = "List network interfaces and IP addresses for all active network interfaces";
        };

        ip = {
          body = "dig +short myip.opendns.com @resolver1.opendns.com $argv";
          wraps = "dig +short myip.opendns.com @resolver1.opendns.com";
          description = "get public ip address";
        };

        ips = {
          body = ''
            ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, ""); print }' $argv
          '';
          description = "Show all ip addresses for machine";
        };

        localip = {
          body = "ipconfig getifaddr en0 $argv";
          description = "get local ip address";
        };

        pbj = {
          body = "pbpaste | jq $argv";
          description = "pretty print json from clipboard";
        };

        raycast = {
          body = builtins.readFile ../files/fish/functions/raycast.fish;
          description = "kill and restart raycast";
        };

        schediff = {
          body = builtins.readFile ../files/fish/functions/schediff.fish;
          description = "Diff array of payment schedules";
        };

        show = {
          body = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
          description = "show hidden files in finder";
        };

        sops_staging = {
          body = ''
            aws_change_profile m3p_staging
            set -gx SOPS_KMS_ARN "arn:aws:kms:us-west-2:211125772151:key/mrk-d167c0b6c99945fabfc4b629d52450ad"
            sops $argv
          '';
          description = "Run sops with the staging profile";
        };

        sops_uat = {
          body = ''
            aws_change_profile m3p_uat
            set -gx SOPS_KMS_ARN "arn:aws:kms:us-west-2:590183679435:key/mrk-3c092342ff9a488399c0ffee8e89eb53"
            sops $argv
          '';
          description = "Run sops with the uat profile";
        };

        sops_production = {
          body = ''
            aws_change_profile m3p_production
            set -gx SOPS_KMS_ARN "arn:aws:kms:us-west-2:533267267027:key/mrk-17f6bf15417942fd9237ed50d33363ca"
            sops $argv
          '';
          description = "Run sops with the production profile";
        };

        tf = {
          body = "terraform $argv";
          description = "terraform";
          wraps = "terraform";
        };

        tst = {
          body = builtins.readFile ../files/fish/functions/tst.fish;
          description = "Run tests based on the project type";
        };

        watch = {
          body = builtins.readFile ../files/fish/functions/watch.fish;
          description = "watch command";
        };

        weather = {
          body = "curl wttr.in $argv";
          description = "get weather";
        };

        y = {
          body = builtins.readFile ../files/fish/functions/y.fish;
          description = "yazi";
        };

        zoxide_register_children = {
          body = builtins.readFile ../files/fish/functions/zoxide_register_children.fish;
          description = "Adds immediate child directories of the current directory to zoxide's database.";
        };

        nv = {
          body = builtins.readFile ../files/fish/functions/nv.fish;
          description = "Select and launch Neovim with a specific configuration using fzf";
        };
      };

      plugins = [
        {
          name = "z";
          src = pkgs.fetchFromGitHub {
            owner = "mholtzscher";
            repo = "worky";
            rev = "1.0.0";
            sha256 = "sha256-YS7gZdRgKP7V9TXWkuffyBo0bMA9okAyTbpJvVTVwI0=";
          };
        }
      ];
    };
  };
}
