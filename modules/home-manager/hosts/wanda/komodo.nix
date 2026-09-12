# Komodo trial stack for Wanda (Ubuntu + standalone Home Manager).
#
# Wanda is not NixOS, so this module only uses Home Manager options:
#   - generates ~/komodo/compose.yaml for `docker compose`
#   - installs the Periphery onboarding helper
#
# Only Mongo and Komodo Core run as containers. Periphery runs as a root
# systemd service on the host and is installed by the helper below, because
# the agent needs direct docker access.
#
# Secret *values* never enter the Nix store: the four agenix secrets are
# declared in modules/home-manager/secrets.nix and referenced from the
# Compose document by file path only.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  komodoVersion = "2.3.3";
  komodoFerretDbVersion = "2.7.0";
  komodoPostgresDocumentDbVersion = "17-0.107.0-ferretdb-2.7.0";

  # Keep the origin bound to Wanda's LAN address. Browser access uses the
  # Cloudflare Access-protected external URL, while Periphery connects directly
  # over the LAN and does not depend on the tunnel.
  komodoExternalUrl = "https://wanda.holtzscher.com";
  komodoLanAddress = "10.69.69.60";
  # Tailnet node `tailscale-wanda` (verify with `tailscale ip -4` on wanda).
  # Bound so the Komodo MCP client can reach Core on and off the LAN over
  # WireGuard-encrypted Tailscale instead of the LAN-only address. This must
  # stay a literal IP — Docker port bindings don't resolve hostnames. Clients
  # use the MagicDNS name `tailscale-wanda.tailea9b59.ts.net` (see KOMODO_URL
  # in modules/home-manager/agents/pi.nix), which keeps working across
  # reinstalls even if this IP changes.
  komodoTailscaleAddress = "100.112.7.108";
  komodoCorePort = 9120;

  # Docker Compose reads secrets from plain files on the host, so the agenix
  # entries for these names use `symlink = false` and an explicit path. Keep
  # this in sync with modules/home-manager/secrets.nix.
  agenixSecretPath = name: "${config.home.homeDirectory}/.local/share/agenix/${name}";
  composeSecretPath = name: "/run/secrets/${name}";

  komodoDatabaseEnvironmentSecret = "komodo-database-environment";
  komodoInitAdminPasswordSecret = "komodo-init-admin-password";
  komodoJwtSecret = "komodo-jwt-secret";
  komodoWebhookSecret = "komodo-webhook-secret";

  komodoComposeSecretNames = [
    komodoInitAdminPasswordSecret
    komodoJwtSecret
    komodoWebhookSecret
  ];

  komodoBackupsDir = "${config.home.homeDirectory}/komodo/backups";

  # MongoDB cannot run on wanda's Linux 7.0.0 kernel because of MongoDB
  # SERVER-121912. Komodo's supported FerretDB topology provides the Mongo wire
  # protocol over PostgreSQL without that kernel incompatibility.
  #
  # Docker Compose reads this owner-only agenix env file as root. The database
  # password is therefore absent from the generated Compose file and Nix store,
  # but is visible to root-equivalent Docker API clients through container env.
  komodoDatabaseEnvironmentFile = agenixSecretPath komodoDatabaseEnvironmentSecret;

  komodoPostgresService = {
    image = "ghcr.io/ferretdb/postgres-documentdb:${komodoPostgresDocumentDbVersion}";
    container_name = "komodo-postgres";
    restart = "unless-stopped";
    env_file = [ komodoDatabaseEnvironmentFile ];
    environment = {
      POSTGRES_USER = "komodo";
      POSTGRES_DB = "postgres";
    };
    volumes = [ "postgres-data:/var/lib/postgresql/data" ];
    labels."komodo.skip" = "";
  };

  komodoFerretDbService = {
    image = "ghcr.io/ferretdb/ferretdb:${komodoFerretDbVersion}";
    container_name = "komodo-ferretdb";
    restart = "unless-stopped";
    depends_on = [ "postgres" ];
    env_file = [ komodoDatabaseEnvironmentFile ];
    volumes = [ "ferretdb-state:/state" ];
    labels."komodo.skip" = "";
  };

  komodoCoreService = {
    image = "ghcr.io/moghtech/komodo-core:${komodoVersion}";
    container_name = "komodo-core";
    init = true;
    restart = "unless-stopped";
    depends_on = [ "ferretdb" ];
    ports = [
      "${komodoLanAddress}:${toString komodoCorePort}:${toString komodoCorePort}"
      "${komodoTailscaleAddress}:${toString komodoCorePort}:${toString komodoCorePort}"
    ];
    env_file = [ komodoDatabaseEnvironmentFile ];
    environment = {
      KOMODO_DATABASE_ADDRESS = "ferretdb:27017";
      KOMODO_DATABASE_USERNAME = "komodo";
      KOMODO_HOST = komodoExternalUrl;
      KOMODO_TITLE = "Komodo — Wanda";
      TZ = "America/Chicago";
      KOMODO_LOCAL_AUTH = "true";
      KOMODO_INIT_ADMIN_USERNAME = "michael";
      KOMODO_INIT_ADMIN_PASSWORD_FILE = composeSecretPath komodoInitAdminPasswordSecret;
      KOMODO_JWT_SECRET_FILE = composeSecretPath komodoJwtSecret;
      KOMODO_JWT_TTL = "1-day";
      KOMODO_WEBHOOK_SECRET_FILE = composeSecretPath komodoWebhookSecret;
      KOMODO_DISABLE_USER_REGISTRATION = "true";
      KOMODO_ENABLE_NEW_USERS = "false";
      KOMODO_DISABLE_NON_ADMIN_CREATE = "true";
      # Keep the full confirmation dialog on action buttons.
      KOMODO_DISABLE_CONFIRM_DIALOG = "false";
      # Skip the default "Backup Core Database" / "Global Auto Update" resources.
      KOMODO_DISABLE_INIT_RESOURCES = "true";
    };
    secrets = komodoComposeSecretNames;
    volumes = [
      # Persist the Core/Periphery noise keys across recreates.
      "core-keys:/config/keys"
      "${komodoBackupsDir}:/backups"
    ];
    labels."komodo.skip" = "";
  };

  komodoComposeDocument = {
    name = "komodo";
    services = {
      postgres = komodoPostgresService;
      ferretdb = komodoFerretDbService;
      core = komodoCoreService;
    };
    secrets = lib.genAttrs komodoComposeSecretNames (name: {
      file = agenixSecretPath name;
    });
    volumes = {
      postgres-data = null;
      ferretdb-state = null;
      core-keys = null;
    };
  };

  komodoComposeFile = (pkgs.formats.yaml { }).generate "komodo-compose.yaml" komodoComposeDocument;

  # Periphery is distributed as a prebuilt Go binary; no build needed.
  komodoPeripheryBinary = pkgs.fetchurl {
    url = "https://github.com/moghtech/komodo/releases/download/v${komodoVersion}/periphery-x86_64";
    hash = "sha256-QLePN3YmeZr62DMSRqUB8HfU68+22QlolM9Vtk9tzxM=";
  };

  komodoPeriphery = pkgs.runCommand "komodo-periphery-${komodoVersion}" { } ''
    install -Dm755 ${komodoPeripheryBinary} $out/bin/komodo-periphery
  '';

  # Everything except the onboarding key, which is only known at install time.
  komodoPeripheryConfig = pkgs.writeText "komodo-periphery.config.toml" ''
    root_directory = "/etc/komodo"
    core_address = "ws://${komodoLanAddress}:${toString komodoCorePort}"
    connect_as = "wanda"
    disable_terminals = true
    disable_container_terminals = true
    # Use the unconfined Nix Compose client. The snap Docker CLI cannot read
    # Git checkouts under /etc/komodo and rewrites them to /var/lib/snapd/void.
    legacy_compose_cli = true
    include_disk_mounts = ["/"]
    logging.level = "info"
    logging.stdio = "standard"
  '';

  komodoPeripheryUnit = pkgs.writeText "komodo-periphery.service" ''
    [Unit]
    Description=Komodo Periphery agent for wanda
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    Environment=HOME=/root
    Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
    # Git remotes contain the provider token, so Periphery-created files must
    # never be readable by other local users.
    UMask=0077
    ExecStart=/usr/local/bin/komodo-periphery --config-path /etc/komodo/periphery.config.toml
    Restart=on-failure
    RestartSec=10
    TimeoutStartSec=0

    [Install]
    WantedBy=multi-user.target
  '';

  # Run interactively on wanda *after* Komodo Core is up and a Server
  # onboarding key has been created in the Komodo UI (Servers -> New Server ->
  # Onboarding Key). Installs the pinned Periphery binary, its root-only config
  # and its systemd unit, then enables the service.
  installKomodoPeriphery = pkgs.writeShellApplication {
    name = "install-komodo-periphery-wanda";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gnugrep
    ];
    text = ''
      periphery_binary_source="${komodoPeriphery}/bin/komodo-periphery"
      periphery_install_path="/usr/local/bin/komodo-periphery"
      compose_binary_source="${pkgs.docker-compose}/bin/docker-compose"
      compose_install_path="/usr/local/bin/docker-compose"
      periphery_root_directory="/etc/komodo"
      periphery_config_path="/etc/komodo/periphery.config.toml"
      periphery_unit_path="/etc/systemd/system/komodo-periphery.service"
      core_health_url="http://${komodoLanAddress}:${toString komodoCorePort}/"
      expected_hostname="wanda"

      log() { printf '==> %s\n' "$*"; }
      die() { printf 'error: %s\n' "$*" >&2; exit 1; }

      [ -t 0 ] || die "run this helper interactively on wanda"
      [ "$(hostname -s)" = "$expected_hostname" ] \
        || die "expected hostname $expected_hostname, got '$(hostname -s)'"
      [ -x "$periphery_binary_source" ] \
        || die "periphery binary not found at $periphery_binary_source"
      command -v sudo >/dev/null 2>&1 || die "sudo not found"

      log "checking Komodo Core at $core_health_url"
      core_http_status="$(curl --silent --show-error --max-time 10 --output /dev/null \
        --write-out '%{http_code}' "$core_health_url")" \
        || die "Komodo Core is not reachable at $core_health_url"
      [[ "$core_http_status" =~ ^[1-5][0-9]{2}$ ]] \
        || die "Komodo Core did not answer with an HTTP status (got '$core_http_status')"
      log "Komodo Core answered with HTTP $core_http_status"

      printf 'Paste the Server onboarding key from the Komodo UI: ' >&2
      IFS= read -r -s onboarding_key
      printf '\n' >&2
      [ -n "$onboarding_key" ] || die "no onboarding key provided"
      # Single-line base64-ish token; rejects anything that could break TOML.
      [[ "$onboarding_key" =~ ^[A-Za-z0-9+/=_-]{16,512}$ ]] \
        || die "onboarding key is not a single-line token"

      work_dir="$(mktemp -d)"
      cleanup() { rm -rf -- "$work_dir"; }
      trap cleanup EXIT INT TERM

      # `install -m 0600` (not `cp`): store paths are read-only, and `cp`
      # carries that mode over to the copy, which makes the append below fail.
      install -m 0600 ${komodoPeripheryConfig} "$work_dir/periphery.config.toml"
      printf 'onboarding_key = "%s"\n' "$onboarding_key" >> "$work_dir/periphery.config.toml"

      log "installing Periphery and the unconfined Compose client"
      sudo install -d -m 0755 "$periphery_root_directory"
      sudo install -m 0755 "$periphery_binary_source" "$periphery_install_path"
      sudo install -m 0755 "$compose_binary_source" "$compose_install_path"
      sudo install -m 0600 -o root -g root \
        "$work_dir/periphery.config.toml" "$periphery_config_path"
      sudo install -m 0644 -o root -g root \
        ${komodoPeripheryUnit} "$periphery_unit_path"

      log "enabling komodo-periphery.service"
      sudo systemctl daemon-reload
      sudo systemctl enable komodo-periphery.service
      sudo systemctl restart komodo-periphery.service

      log "done. Check with: sudo systemctl status komodo-periphery.service"
    '';
  };
in
{
  # Docker is installed as a strictly confined snap on wanda. Its Compose
  # plugin cannot follow a Home Manager symlink into /nix/store, so install a
  # regular file instead of declaring home.file."komodo/compose.yaml".
  home.activation.installKomodoComposeFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run rm -f "${config.home.homeDirectory}/komodo/compose.yaml"
    run install -Dm0600 ${komodoComposeFile} "${config.home.homeDirectory}/komodo/compose.yaml"
    run mkdir -p "${komodoBackupsDir}"
    run chmod 0700 "${komodoBackupsDir}"
  '';

  home.packages = [ installKomodoPeriphery ];
}
