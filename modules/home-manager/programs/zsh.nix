{
  config,
  lib,
  isWork,
  isDarwin,
  ...
}:
let
  sharedAliases = import ../shared-aliases.nix { inherit isWork; };
  readAgeSecret = path: "$(secret=${path}; [[ -r $secret ]] && cat $secret)";
  workOnboardingScript = ''
    if [ -f /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh ]; then
        source /Users/michaelholtzcher/code/paytient/onboarding/engineering.sh
        export GITHUB_PAT=$(security find-generic-password -s github-packages-pat -w)
        export GITHUB_TOKEN=$(security find-generic-password -s github-packages-pat -w )
        export HOMEBREW_GITHUB_API_TOKEN=$(security find-generic-password -s github-packages-pat -w )
    fi
  '';
in
{
  # Retain the shell package/integrations, but let Mise own Mac startup files.
  home.file = lib.mkIf isDarwin {
    "./.zshrc".enable = false;
    "./.zshenv".enable = false;
    "./.zprofile".enable = false;
  };

  programs = {
    zsh = {
      enable = true;
      shellAliases = sharedAliases.shellAliases // {
        ls = "eza";
        la = "eza -a";
        lla = "eza -la";
        lt = "eza --tree";
      };
      initContent = lib.mkMerge [
        (lib.mkOrder 1100 ''
          source <(carapace _carapace zsh)
          eval "$(zoxide init zsh)"
          function yy() {
            local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
            command yazi "$@" --cwd-file="$tmp"
            if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              builtin cd -- "$cwd"
            fi
            rm -f -- "$tmp"
          }
          if [[ $options[zle] = on ]]; then
            export FZF_CTRL_R_COMMAND=""
            source <(fzf --zsh)
          fi
        '')
        (lib.mkOrder 1200 ''
          if [[ $TERM != "dumb" ]]; then
            eval "$(starship init zsh)"
          fi
        '')
        (lib.mkOrder 1300 ''
          if [[ $options[zle] = on ]]; then
            ${
              if isWork then
                ''eval "$(atuin init zsh)"''
              else
                ''
                  if [[ -r ${config.age.secrets.atuin-key.path} ]]; then
                    eval "$(atuin init zsh)"
                  fi
                ''
            }
          fi
        '')
        ''
          ${builtins.readFile ../files/zsh/herdr-nix-status.zsh}
          ${if isWork then workOnboardingScript else ""}
        ''
      ];
      sessionVariables = {
        # Bun installs global executable shims in ~/.bun/bin by default.
        PATH = "$PATH:$HOME/.local/bin:$HOME/.bun/bin";
      }
      // lib.optionalAttrs (!isWork) {
        GITHUB_PERSONAL_ACCESS_TOKEN = readAgeSecret config.age.secrets.github-pat.path;
        AGENT_ARTIFACTS_BASE_URL = "https://artifacts.holtzscher.com";
        AGENT_ARTIFACTS_WRITE_KEY = readAgeSecret config.age.secrets.agent-artifacts-write-key.path;
      };
    };
  };
}
