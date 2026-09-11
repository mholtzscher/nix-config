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

    secrets.github-pat.file = ../../secrets/github-pat.age;
    secrets.atuin-key = {
      file = ../../secrets/atuin-key.age;
      # Atuin reads this path itself, so it cannot expand agenix's Darwin
      # runtime-directory shell expression.
      path = "${config.home.homeDirectory}/.local/share/agenix/atuin-key";
    };
    secrets.agent-artifacts-write-key.file = ../../secrets/agent-artifacts-write-key.age;
    # Explicit path: pi-mcp-adapter's !command env injection cannot expand
    # agenix's Darwin runtime-directory shell expression.
    secrets.unifi-password = lib.mkIf (currentSystemName != "wanda") {
      file = ../../secrets/unifi-password.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/unifi-password";
    };

    # Komodo trial stack on Wanda. Docker Compose reads these as file-backed
    # secrets, so `symlink = false` writes the decrypted value straight to the
    # explicit path instead of the per-boot runtime directory. Keep the paths
    # and names in sync with modules/home-manager/hosts/wanda/komodo.nix.
    secrets.komodo-database-environment = lib.mkIf (currentSystemName == "wanda") {
      file = ../../secrets/komodo-database-environment.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/komodo-database-environment";
      symlink = false;
    };
    secrets.komodo-init-admin-password = lib.mkIf (currentSystemName == "wanda") {
      file = ../../secrets/komodo-init-admin-password.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/komodo-init-admin-password";
      symlink = false;
    };
    secrets.komodo-jwt-secret = lib.mkIf (currentSystemName == "wanda") {
      file = ../../secrets/komodo-jwt-secret.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/komodo-jwt-secret";
      symlink = false;
    };
    secrets.komodo-webhook-secret = lib.mkIf (currentSystemName == "wanda") {
      file = ../../secrets/komodo-webhook-secret.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/komodo-webhook-secret";
      symlink = false;
    };
  };

  # Upstream also sets Crashed = false, which restarts the agent after every
  # clean exit. Retry only failed decryptions.
  launchd.agents.activate-agenix.config.KeepAlive = lib.mkIf (!isWork && isDarwin) (
    lib.mkForce {
      SuccessfulExit = false;
    }
  );
}
