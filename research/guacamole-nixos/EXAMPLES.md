# Guacamole Configuration Examples for NixOS

## Example 1: Minimal Setup with User Mapping

Perfect for small deployments or testing.

```nix
# modules/nixos/hosts/guacamole-host/default.nix

{ config, lib, pkgs, ... }:

{
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4822;
    userMappingXml = ./user-mapping.xml;
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;
    };
  };

  # Allow port 8080 for local access
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
```

Create `user-mapping.xml` in the same directory:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
  <!-- Admin user -->
  <authorize username="admin" password="change-me-now">
    <!-- RDP connection -->
    <connection name="Windows Server">
      <protocol>rdp</protocol>
      <param name="hostname">192.168.1.100</param>
      <param name="port">3389</param>
      <param name="username">admin</param>
      <param name="password">rdp-password</param>
      <param name="domain">DOMAIN</param>
      <param name="ignore-cert">true</param>
      <param name="enable-drive">true</param>
      <param name="drive-path">/tmp/guacamole-drive</param>
    </connection>

    <!-- VNC connection -->
    <connection name="VNC Desktop">
      <protocol>vnc</protocol>
      <param name="hostname">192.168.1.50</param>
      <param name="port">5900</param>
      <param name="password">vnc-password</param>
    </connection>

    <!-- SSH connection -->
    <connection name="SSH Server">
      <protocol>ssh</protocol>
      <param name="hostname">ssh.example.com</param>
      <param name="port">22</param>
      <param name="username">sshuser</param>
      <param name="private-key">~/.ssh/id_rsa</param>
    </connection>
  </authorize>

  <!-- Regular user -->
  <authorize username="user1" password="user1-pass">
    <connection name="Shared Windows">
      <protocol>rdp</protocol>
      <param name="hostname">192.168.1.100</param>
      <param name="port">3389</param>
      <param name="username">user1</param>
      <param name="password">user1-rdp-pass</param>
    </connection>
  </authorize>
</user-mapping>
```

---

## Example 2: Production with PostgreSQL & Caddy

For production deployments with database authentication and HTTPS.

```nix
# modules/nixos/hosts/guacamole-prod/default.nix

{ config, lib, pkgs, ... }:

{
  # PostgreSQL database
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 md5
    '';
  };

  # Initialize guacamole database on first boot
  system.activationScripts.guacamoleDbInit = lib.mkBefore ''
    if ! ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -l 2>/dev/null | grep -q guacamole; then
      echo "Creating guacamole database..."
      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/createdb guacamole
      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/createuser guacamole 2>/dev/null || true
      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -d guacamole -c "ALTER USER guacamole WITH PASSWORD 'guacamole';"
    fi
  '';

  # Guacamole services
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4822;
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      # guacd connection
      guacd-hostname = "localhost";
      guacd-port = 4822;

      # PostgreSQL database connection
      postgresql-hostname = "localhost";
      postgresql-port = 5432;
      postgresql-database = "guacamole";
      postgresql-username = "guacamole";
      postgresql-password = "guacamole";  # TODO: Use agenix for secrets!

      # Feature configuration
      user-timeout = "300000";  # 5 minutes
      enable-clipboard-integration = "true";
    };
  };

  # Caddy reverse proxy
  services.caddy = {
    enable = true;
    email = "admin@example.com";
    
    virtualHosts."guacamole.example.com" = {
      extraConfig = ''
        encode gzip
        
        reverse_proxy localhost:8080 {
          # Important: disable buffering for WebSocket
          flush_interval -1
          
          # Add headers for Tomcat
          header_up X-Forwarded-Host {host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Real-IP {remote_host}
        }
      '';
    };
  };

  # Firewall rules
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];  # HTTP and HTTPS
    allowedUDPPorts = [ 443 ];     # QUIC
  };

  # Dependencies
  systemd.services.guacamole-client = {
    after = [ "postgresql.service" ];
  };
}
```

---

## Example 3: Complete Lab Setup with Multiple Services

Guacamole with Nginx, MySQL, and multiple backends.

```nix
# modules/nixos/hosts/guacamole-lab/default.nix

{ config, lib, pkgs, ... }:

{
  # MySQL database
  services.mysql = {
    enable = true;
    package = pkgs.mysql80;
    settings = {
      mysqld = {
        max_connections = 50;
        key_buffer_size = "256M";
        bind-address = "127.0.0.1";
      };
    };
  };

  # Guacamole services
  services.guacamole-server = {
    enable = true;
    host = "0.0.0.0";  # Listen on all interfaces
    port = 4822;
    extraEnvironment = {
      ENVIRONMENT = "production";
      DEBUG_LEVEL = "INFO";
    };
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;

      # MySQL database
      mysql-hostname = "localhost";
      mysql-port = 3306;
      mysql-database = "guacamole";
      mysql-username = "guacamole";
      mysql-password = "secure-password";

      # Performance tuning
      user-timeout = "600000";  # 10 minutes
      session-timeout = "3600000";  # 1 hour
    };
  };

  # Nginx reverse proxy
  services.nginx = {
    enable = true;
    virtualHosts."guac.lab" = {
      locations."/" = {
        proxyPass = "http://localhost:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_request_buffering off;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          proxy_connect_timeout 75s;
        '';
      };
    };
  };

  # Test backend RDP server (xrdp on another host)
  # or use Docker container for testing
  virtualisation.docker.enable = true;

  # Enable SSH for direct access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ 22 80 443 3306 4822 8080 ];
  };

  # Tomcat optimization
  services.tomcat = {
    jvmOpts = [ "-Xms512m" "-Xmx1024m" "-XX:+UseG1GC" ];
  };
}
```

---

## Example 4: Community Podman-Based Setup

Using Podman containers for guacd and PostgreSQL.

```nix
# modules/nixos/hosts/guacamole-podman/default.nix

{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
  };

  # Only Tomcat runs on host, backend services in containers
  services.guacamole-client = {
    enable = true;
    settings = {
      # Connect to guacd in container
      guacd-hostname = "guacd";
      guacd-port = 4822;

      # PostgreSQL in container
      postgresql-hostname = "postgres";
      postgresql-port = 5432;
      postgresql-database = "guacamole";
      postgresql-username = "guacamole";
      postgresql-password = "container-password";
    };
  };

  # Create containers
  systemd.services.guacamole-guacd = {
    description = "Guacd container";
    after = [ "podman.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.podman}/bin/podman run --rm "
        + "--name guacd "
        + "--network guacamole-net "
        + "docker.io/guacamole/guacd:1.6.0";
      Restart = "on-failure";
    };
  };

  systemd.services.guacamole-postgres = {
    description = "PostgreSQL container for Guacamole";
    after = [ "podman.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.podman}/bin/podman run --rm "
        + "--name postgres "
        + "--network guacamole-net "
        + "-e POSTGRES_DB=guacamole "
        + "-e POSTGRES_USER=guacamole "
        + "-e POSTGRES_PASSWORD=container-password "
        + "-v /var/lib/guacamole-postgres:/var/lib/postgresql/data "
        + "docker.io/postgres:15";
      Restart = "on-failure";
    };
  };

  # Create network
  systemd.services.guacamole-network = {
    description = "Create Guacamole Podman network";
    after = [ "podman.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create -d bridge guacamole-net || true";
    };
  };

  # Caddy reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts."guac.example.com" = {
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

## Example 5: Minimal Setup for Testing

Quick test environment:

```nix
{ ... }:

{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;

  # For testing, allow all TCP
  networking.firewall.enable = false;
}
```

Then access at: `http://<host>:8080/guacamole`

---

## Example 6: User Mapping with SSH Keys

For secure SSH connections with key authentication:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
  <authorize username="devops" password="devops-password">
    <connection name="Production Server">
      <protocol>ssh</protocol>
      <param name="hostname">prod.example.com</param>
      <param name="port">22</param>
      <param name="username">devops</param>
      <param name="private-key">~/.ssh/keys/prod_key</param>
      <param name="passphrase">key-passphrase</param>
      <param name="color-scheme">linux</param>
      <param name="font-size">14</param>
    </connection>

    <connection name="Dev Server">
      <protocol>ssh</protocol>
      <param name="hostname">dev.example.com</param>
      <param name="port">2222</param>
      <param name="username">devops</param>
      <param name="private-key">~/.ssh/keys/dev_key</param>
    </connection>
  </authorize>
</user-mapping>
```

---

## Common Configuration Patterns

### Performance Tuning

```nix
{
  services.tomcat = {
    jvmOpts = [
      "-Xms1g"          # Initial heap size
      "-Xmx2g"          # Max heap size
      "-XX:+UseG1GC"    # Garbage collector
      "-XX:MaxGCPauseMillis=200"
    ];
  };

  services.guacamole-client.settings = {
    user-timeout = "600000";        # 10 min idle disconnect
    session-timeout = "3600000";    # 1 hour total timeout
    session-warning-timeout = "60000";  # 1 min warning
  };
}
```

### Logging Configuration

```nix
{
  services.guacamole-client.settings = {
    "log4j.rootCategory" = "INFO,FILE,SYSLOG";
    "log4j.appender.FILE" = "org.apache.log4j.FileAppender";
    "log4j.appender.FILE.File" = "/var/log/guacamole/guacamole.log";
    "log4j.appender.SYSLOG" = "org.apache.log4j.net.SyslogAppender";
    "log4j.appender.SYSLOG.SyslogHost" = "localhost";
  };
}
```

### High Availability with Load Balancer

```nix
{
  # Multiple Guacamole instances
  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "guacd-cluster";  # DNS round-robin
    };
  };

  # Shared PostgreSQL backend
  services.postgresql = {
    enable = true;
  };

  # HAProxy load balancer
  services.haproxy = {
    enable = true;
    config = ''
      frontend guacamole
        bind *:80
        default_backend guacamole_backends

      backend guacamole_backends
        balance roundrobin
        server guac1 localhost:8080
        server guac2 localhost:8081
    '';
  };
}
```
