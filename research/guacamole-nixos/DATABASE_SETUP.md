# Database Setup for Guacamole on NixOS

## Overview

While user-mapping.xml works for simple deployments, production Guacamole setups use a database for:

- **User management**: Easy add/remove users
- **Connection management**: Add/edit connections without rebuild
- **Audit logging**: Track who accessed what and when
- **Advanced features**: OIDC, LDAP, custom authentication

Supported databases:
- **PostgreSQL** (recommended)
- **MySQL** / MariaDB
- **SQLServer** (community)
- **Oracle** (community)

## PostgreSQL Setup (Recommended)

### Basic Configuration

```nix
{
  # PostgreSQL database server
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    settings = {
      # Allow connections from Tomcat
      max_connections = 100;
      shared_buffers = "256MB";
    };
  };

  # Guacamole services
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4822;
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;

      # PostgreSQL connection
      postgresql-hostname = "localhost";
      postgresql-port = 5432;
      postgresql-database = "guacamole";
      postgresql-username = "guacamole";
      # Password handled via environment or socket auth
    };
  };
}
```

### Database Initialization

Create initialization script `guacamole-init.sql`:

```sql
-- Create guacamole database
CREATE DATABASE guacamole;
CREATE USER guacamole WITH PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE guacamole TO guacamole;

-- Connect to the database
\c guacamole

-- Initialize schema (downloaded from Guacamole)
-- Replace with actual schema SQL from:
-- https://github.com/apache/guacamole-client/blob/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/001-create-schema.sql
```

### NixOS Integration

Initialize database on activation:

```nix
{
  services.postgresql = {
    enable = true;
    
    # Run initialization script
    initialScript = pkgs.writeText "init-guacamole.sql" ''
      CREATE ROLE guacamole WITH LOGIN PASSWORD 'temp-password';
      CREATE DATABASE guacamole OWNER guacamole;
      GRANT ALL PRIVILEGES ON DATABASE guacamole TO guacamole;
    '';
  };
}
```

### Credentials Management

**⚠️ IMPORTANT**: Don't store passwords in Nix store! Use secrets management:

```nix
# Option 1: agenix for secrets
{
  age.secrets.guacamole-db-password.file = ./secrets/guacamole-db-password.age;
  
  services.guacamole-client.settings = {
    postgresql-password-file = config.age.secrets.guacamole-db-password.path;
  };
}

# Option 2: Environment variables (from /etc/guacamole/guacamole.properties)
{
  environment.variables.POSTGRESQL_PASSWORD = "@/run/secrets/guacamole-db-password";
}
```

## MySQL / MariaDB Setup

### Configuration

```nix
{
  services.mysql = {
    enable = true;
    package = pkgs.mysql80;  # or pkgs.mariadb
    settings = {
      mysqld = {
        max_connections = 100;
        key_buffer_size = "256M";
      };
    };
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;

      # MySQL connection
      mysql-hostname = "localhost";
      mysql-port = 3306;
      mysql-database = "guacamole";
      mysql-username = "guacamole";
      # Password via agenix or environment
    };
  };
}
```

### Database Initialization

```sql
-- Create database and user
CREATE DATABASE guacamole;
CREATE USER 'guacamole'@'localhost' IDENTIFIED BY 'your-secure-password';
GRANT ALL PRIVILEGES ON guacamole.* TO 'guacamole'@'localhost';
FLUSH PRIVILEGES;

-- Schema will be initialized by Guacamole on first connection
```

## Schema Download & Management

Guacamole requires JDBC schema to be loaded into the database.

### Option 1: Download and Apply Manually

```bash
# Get schema files (version should match guacamole-client version)
wget https://raw.githubusercontent.com/apache/guacamole-client/1.6.0/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/*.sql

# Apply to PostgreSQL
psql -U guacamole -d guacamole -f 001-create-schema.sql
psql -U guacamole -d guacamole -f 002-base-objects.sql
# ... apply remaining schema files

# Verify
psql -U guacamole -d guacamole -c "\dt"
```

### Option 2: Use NixOS Activation Script

```nix
{
  services.postgresql.enable = true;
  
  system.activationScripts.guacamoleDbInit = ''
    if ! ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -d guacamole -c "SELECT * FROM guacamole_user LIMIT 1;" 2>/dev/null; then
      echo "Initializing Guacamole database..."
      # Download and apply schema
      ${pkgs.curl}/bin/curl -o /tmp/guacamole-schema.sql \
        https://raw.githubusercontent.com/apache/guacamole-client/1.6.0/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/001-create-schema.sql
      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -d guacamole -f /tmp/guacamole-schema.sql
    fi
  '';
}
```

## JDBC Driver Configuration

### PostgreSQL Driver

The `postgresql-jdbc` driver is required:

```nix
{
  # Ensure JDBC driver is in classpath
  services.tomcat.environment = {
    CLASSPATH = "${pkgs.postgresql-jdbc}/share/java/*";
  };

  # Or add to lib directory
  system.activationScripts.guacamoleJdbc = ''
    mkdir -p ${config.services.tomcat.home}/lib
    ln -sf ${pkgs.postgresql-jdbc}/share/java/*.jar ${config.services.tomcat.home}/lib/
  '';
}
```

### MySQL Driver

```nix
{
  services.tomcat.environment = {
    CLASSPATH = "${pkgs.mysql-connector-java}/share/java/*";
  };
}
```

## Connection Settings Reference

### PostgreSQL Settings

```nix
settings = {
  # Connection
  postgresql-hostname = "localhost";
  postgresql-port = 5432;
  postgresql-database = "guacamole";
  postgresql-username = "guacamole";
  postgresql-password = "...";  # Use agenix!
  
  # Optional
  postgresql-ssl-mode = "require";     # Require SSL
  postgresql-connection-timeout = 30;  # Seconds
};
```

### MySQL Settings

```nix
settings = {
  # Connection
  mysql-hostname = "localhost";
  mysql-port = 3306;
  mysql-database = "guacamole";
  mysql-username = "guacamole";
  mysql-password = "...";  # Use agenix!
  
  # Optional
  mysql-ssl-mode = "require";
  mysql-connection-timeout = 30;
};
```

## Authentication Providers

Once database is configured, you can use different auth methods:

### JDBC Auth (Built-in)

```nix
{
  # Just enable the database settings above
  # Guacamole automatically uses JDBC for auth
}
```

### LDAP Auth (Extension)

Requires `guacamole-auth-ldap` extension:

```nix
{
  services.guacamole-client.settings = {
    # LDAP server
    ldap-server = "ldap.example.com";
    ldap-port = 389;
    ldap-user-base-dn = "ou=users,dc=example,dc=com";
    ldap-username-attribute = "uid";
  };
}
```

### OIDC/OAuth (Extension)

Requires `guacamole-auth-openid` extension:

```nix
{
  services.guacamole-client.settings = {
    openid-authorization-endpoint = "https://auth.example.com/oauth/authorize";
    openid-token-endpoint = "https://auth.example.com/oauth/token";
    openid-client-id = "guacamole";
    openid-client-secret = "...";  # Use agenix!
    openid-redirect-uri = "https://guacamole.example.com/";
  };
}
```

## Database Backup & Maintenance

### PostgreSQL Backup

```bash
# Full backup
pg_dump -U guacamole -d guacamole > guacamole-backup.sql

# Restore
psql -U guacamole -d guacamole < guacamole-backup.sql
```

### MySQL Backup

```bash
# Full backup
mysqldump -u guacamole -p guacamole > guacamole-backup.sql

# Restore
mysql -u guacamole -p guacamole < guacamole-backup.sql
```

### Automated Backups in NixOS

```nix
{
  services.postgresql.backupAll = true;  # Daily backups
  services.postgresql.backupPath = "/var/backups/postgresql";

  # Or custom backup script
  systemd.timers.guacamole-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      OnBootSec = "15min";
      AccuracySec = "5min";
    };
  };

  systemd.services.guacamole-backup = {
    script = ''
      ${pkgs.postgresql}/bin/pg_dump -U guacamole guacamole | \
        ${pkgs.gzip}/bin/gzip > /var/backups/guacamole-$(date +%Y%m%d).sql.gz
    '';
    serviceConfig.User = "postgres";
  };
}
```

## Troubleshooting

### Connection Refused
```
ERROR: could not connect to server: Connection refused
```
- Check if PostgreSQL/MySQL is running: `systemctl status postgresql`
- Verify port: `netstat -tlnp | grep 5432`
- Check firewall

### Authentication Failed
```
ERROR: password authentication failed for user "guacamole"
```
- Verify credentials in settings
- Check user exists: `psql -U guacamole -d guacamole -c "\du"`

### Schema Not Found
```
ERROR: relation "guacamole_user" does not exist
```
- Schema hasn't been initialized
- Download and apply schema files
- Verify: `psql -d guacamole -c "\dt"`

### Connection Timeout
```
connection timeout exceeded while establishing a connection
```
- Increase timeout: `postgresql-connection-timeout = 60;`
- Check database server availability
- Verify network connectivity
