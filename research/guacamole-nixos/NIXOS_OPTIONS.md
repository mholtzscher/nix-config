# NixOS Guacamole Configuration Options

## services.guacamole-server

The backend daemon that handles protocol connections (RDP, VNC, SSH, Telnet).

### Options

#### `services.guacamole-server.enable`
- **Type**: `bool`
- **Default**: `false`
- **Description**: Enable Apache Guacamole Server (guacd)

#### `services.guacamole-server.package`
- **Type**: `package`
- **Default**: `pkgs.guacamole-server`
- **Description**: The guacamole-server package to use
- **Example**: `pkgs.guacamole-server` (v1.6.0)

#### `services.guacamole-server.host`
- **Type**: `string`
- **Default**: `"127.0.0.1"`
- **Description**: The host to bind guacd to
- **Common values**:
  - `"127.0.0.1"` - Local only (secure)
  - `"0.0.0.0"` - All interfaces (for remote connections)
  - `"::1"` - IPv6 loopback

#### `services.guacamole-server.port`
- **Type**: `port` (0-65535)
- **Default**: `4822`
- **Description**: Port for guacd to listen on
- **Note**: Default Guacamole port, change only if needed

#### `services.guacamole-server.extraEnvironment`
- **Type**: `attrs of string`
- **Default**: `{}`
- **Description**: Environment variables passed to guacd
- **Example**:
  ```nix
  extraEnvironment = {
    ENVIRONMENT = "production";
    DEBUG_LEVEL = "INFO";
  };
  ```

#### `services.guacamole-server.userMappingXml`
- **Type**: `null or path`
- **Default**: `null`
- **Description**: Path to user-mapping.xml file for simple authentication
- **Example**: `/etc/guacamole/user-mapping.xml`
- **Format**: XML file with user definitions and connection parameters
- **When to use**: Simple deployments, no database needed

#### `services.guacamole-server.logbackXml`
- **Type**: `null or path`
- **Default**: `null`
- **Description**: Path to custom logback.xml for logging configuration
- **Default**: Built-in configuration used if not specified

### Service Configuration

The module automatically creates a systemd service:

```nix
systemd.services.guacamole-server = {
  description = "Apache Guacamole server (guacd)";
  wantedBy = [ "multi-user.target" ];
  after = [ "network.target" ];
  serviceConfig = {
    ExecStart = "${lib.getExe cfg.package} -f -b ${cfg.host} -l ${toString cfg.port}";
    RuntimeDirectory = "guacamole-server";
    DynamicUser = true;           # Runs as dynamic user
    PrivateTmp = "yes";           # Isolated /tmp
    Restart = "on-failure";       # Auto-restart on crash
  };
};
```

---

## services.guacamole-client

The web application that provides the Guacamole UI (runs on Tomcat).

### Options

#### `services.guacamole-client.enable`
- **Type**: `bool`
- **Default**: `false`
- **Description**: Enable Apache Guacamole Client (Tomcat web app)
- **Note**: Also enables `services.tomcat` automatically

#### `services.guacamole-client.package`
- **Type**: `package`
- **Default**: `pkgs.guacamole-client`
- **Description**: The guacamole-client WAR file package
- **Example**: `pkgs.guacamole-client` (v1.6.0)

#### `services.guacamole-client.settings`
- **Type**: `submodule with freeformType`
- **Default**: 
  ```nix
  {
    guacd-hostname = "localhost";
    guacd-port = 4822;
  }
  ```
- **Description**: Configuration written to `guacamole.properties`
- **Format**: Java properties format
- **File location**: `/etc/guacamole/guacamole.properties`

### Important Settings

Key settings for `services.guacamole-client.settings`:

#### Connection to guacd
```nix
settings = {
  guacd-hostname = "localhost";    # guacd server hostname
  guacd-port = 4822;               # guacd server port
  guacd-ssl = false;               # Enable SSL to guacd (if configured)
};
```

#### Authentication Methods

**User Mapping (server-side)**:
```nix
# Configure in guacamole-server.userMappingXml
# No settings needed here
```

**JDBC Database**:
```nix
settings = {
  # PostgreSQL
  "guacamole.properties" = ''
    # Database driver - downloaded separately
    # See DATABASE_SETUP.md
  '';
};
```

#### Logging
```nix
settings = {
  "log4j.rootCategory" = "INFO,FILE,SYSLOG";
  "log4j.appender.FILE" = "org.apache.log4j.FileAppender";
  "log4j.appender.FILE.File" = "/var/log/guacamole/guacamole.log";
};
```

#### Proxy Headers (for reverse proxy)
```nix
settings = {
  "allow-user-connections" = "true";
  "allow-simultaneous-connections" = "true";
};
```

#### Session Management
```nix
settings = {
  "user-timeout" = "300000";                    # 5 minutes in ms
  "session-timeout" = "3600000";                # 1 hour in ms
  "session-warning-timeout" = "60000";          # 1 minute warning
};
```

#### Feature Toggles
```nix
settings = {
  "enable-clipboard-integration" = "true";
  "enable-touch-input" = "true";
  "enable-audio" = "true";
};
```

#### `services.guacamole-client.enableWebserver`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable Tomcat webserver for the web application
- **Note**: Set to `false` if running Guacamole in container or custom setup

---

## services.tomcat

Automatically enabled when `services.guacamole-client.enable = true`.

### Key Tomcat Options Relevant to Guacamole

#### `services.tomcat.enable`
- **Type**: `bool`
- **Auto**: `true` when guacamole-client enabled
- **Description**: Enable Apache Tomcat

#### `services.tomcat.port`
- **Type**: `int`
- **Default**: `8080`
- **Description**: Port Tomcat listens on
- **Note**: Access Guacamole at `http://localhost:8080/guacamole`

#### `services.tomcat.webapps`
- **Type**: `list of packages`
- **Default**: `[ guacamole-client ]` (when guacamole-client enabled)
- **Description**: Web applications to deploy

#### `services.tomcat.jvmOpts`
- **Type**: `list of string`
- **Default**: `[ "-Xms256m" "-Xmx512m" ]`
- **Description**: Java VM options
- **Example** (for performance):
  ```nix
  jvmOpts = [ "-Xms1g" "-Xmx2g" "-XX:+UseG1GC" ];
  ```

#### `services.tomcat.virtualHosts`
- **Type**: `set of submodule`
- **Description**: Virtual host configuration
- **Note**: Usually not needed for Guacamole; use reverse proxy instead

---

## Configuration Patterns

### Simple File-Based Authentication

```nix
{
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
    userMappingXml = ./user-mapping.xml;
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;
    };
  };
}
```

### Database-Based Authentication

```nix
{
  services.mysql = {
    enable = true;
    package = pkgs.mysql80;
  };

  services.guacamole-server.enable = true;

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;
      # Database connection configured via environment or settings
    };
  };
}
```

### Production with Reverse Proxy

```nix
{
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."guacamole.example.com" = {
      extraConfig = ''
        reverse_proxy localhost:8080 {
          flush_interval -1
        }
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

## Module Files Location

In nixpkgs repository:

- **Server module**: `nixos/modules/services/web-apps/guacamole-server.nix`
- **Client module**: `nixos/modules/services/web-apps/guacamole-client.nix`
- **Tests**: `nixos/tests/guacamole-server.nix`
- **Package (server)**: `pkgs/by-name/gu/guacamole-server/package.nix`
- **Package (client)**: `pkgs/by-name/gu/guacamole-client/package.nix`

Version in nixpkgs (as of research date):
- guacamole-server: 1.6.0 (unstable-2025-06-29)
- guacamole-client: 1.6.0
