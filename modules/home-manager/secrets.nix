{
  config,
  inputs,
  lib,
  pkgs,
  isWork,
  isDarwin,
  currentSystemName,
  ...
}:
{
  home.packages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  age = lib.mkIf (!isWork) {
    identityPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519_agenix_${currentSystemName}"
    ];

    secrets.dummy-env.file = ../../secrets/dummy-env.age;
    secrets.sideshow-token.file = ../../secrets/sideshow-token.age;
    secrets.atuin-key = {
      file = ../../secrets/atuin-key.age;
      # Atuin reads this path itself, so it cannot expand agenix's Darwin
      # runtime-directory shell expression.
      path = "${config.home.homeDirectory}/.local/share/agenix/atuin-key";
    };
    secrets.agent-artifacts-write-key.file = ../../secrets/agent-artifacts-write-key.age;
  };

  # Upstream also sets Crashed = false, which restarts the agent after every
  # clean exit. Retry only failed decryptions.
  launchd.agents.activate-agenix.config.KeepAlive = lib.mkIf (!isWork && isDarwin) (
    lib.mkForce {
      SuccessfulExit = false;
    }
  );
}
