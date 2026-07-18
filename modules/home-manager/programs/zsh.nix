{
  config,
  lib,
  isWork,
  ...
}:
let
  sharedAliases = import ../shared-aliases.nix { inherit isWork; };
  readAgeSecret =
    path:
    "$(secret=${path}; for _ in {1..100}; do [[ -r $secret ]] && break; sleep 0.1; done; [[ -r $secret ]] && cat $secret)";
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
        ${if isWork then workOnboardingScript else ""}
      '';
      sessionVariables = {
        PATH = "$PATH:/Users/michael/.local/bin";
      }
      // lib.optionalAttrs (!isWork) {
        DUMMY_SECRET = readAgeSecret config.age.secrets.dummy-env.path;
        SIDESHOW_URL = "https://sideshow.sh";
        SIDESHOW_TOKEN = readAgeSecret config.age.secrets.sideshow-token.path;
        AGENT_ARTIFACTS_BASE_URL = "https://artifacts.holtzscher.com";
        AGENT_ARTIFACTS_WRITE_KEY = readAgeSecret config.age.secrets.agent-artifacts-write-key.path;
      };
    };
  };
}
