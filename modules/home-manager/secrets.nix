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
    secrets.nixos-desktop-cloudflare-tunnel-token = lib.mkIf (currentSystemName == "nixos-desktop") {
      file = ../../secrets/nixos-desktop-cloudflare-tunnel-token.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/nixos-desktop-cloudflare-tunnel-token";
    };
    # Explicit path: pi-mcp-adapter's !command env injection cannot expand
    # agenix's Darwin runtime-directory shell expression.
    secrets.unifi-password = lib.mkIf (currentSystemName != "wanda") {
      file = ../../secrets/unifi-password.age;
      path = "${config.home.homeDirectory}/.local/share/agenix/unifi-password";
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
