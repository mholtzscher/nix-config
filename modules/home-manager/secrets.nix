{
  config,
  inputs,
  lib,
  pkgs,
  isWork,
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
    secrets.atuin-key.file = ../../secrets/atuin-key.age;
    secrets.agent-artifacts-write-key.file = ../../secrets/agent-artifacts-write-key.age;
  };
}
