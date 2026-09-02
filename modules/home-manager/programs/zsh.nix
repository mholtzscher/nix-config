{
  config,
  lib,
  isWork,
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
  programs = {
    zsh = {
      enable = true;
      shellAliases = sharedAliases.shellAliases;
      initContent = ''
        ${builtins.readFile ../files/zsh/herdr-nix-status.zsh}
        ${if isWork then workOnboardingScript else ""}
        ${lib.optionalString (!isWork) ''
          if [[ -r ${config.age.secrets.atuin-key.path} && $options[zle] = on ]]; then
            eval "$(${lib.getExe config.programs.atuin.package} init zsh)"
          fi
        ''}
      '';
      sessionVariables = {
        PATH = "$PATH:/Users/michael/.local/bin";
      }
      // lib.optionalAttrs (!isWork) {
        GITHUB_PERSONAL_ACCESS_TOKEN = readAgeSecret config.age.secrets.github-pat.path;
        AGENT_ARTIFACTS_BASE_URL = "https://artifacts.holtzscher.com";
        AGENT_ARTIFACTS_WRITE_KEY = readAgeSecret config.age.secrets.agent-artifacts-write-key.path;
      };
    };
  };
}
