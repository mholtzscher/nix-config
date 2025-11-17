# Correct NixOS Guacamole Configuration - Verified from nixpkgs

## Executive Summary

✅ **Your research was accurate!** The options documented in `NIXOS_OPTIONS.md` are correct and verified against the actual nixpkgs source code.

However, there's one critical distinction:
- **`services.guacamole-client.userMappingXml` does NOT exist** ❌
- **`services.guacamole-server.userMappingXml` DOES exist** ✅

---

## Correct NixOS Options (Verified)

### Module 1: `services.guacamole-server`

**File**: `nixos/modules/services/web-apps/guacamole-server.nix`

#### Available Options

```nix
services.guacamole-server = {
  # Enable the guacd daemon
  enable = true | false;                    # Default: false
  
  # Package to use
  package = pkgs.guacamole-server;          # Default: pkgs.guacamole-server
  
  # Network binding
  host = "127.0.0.1";                       # Default: "127.0.0.1"
  port = 4822;                              # Default: 4822 (type: port)
  
  # File-based authentication (server-side)
  userMappingXml = null or path;            # Default: null
  # Example: userMappingXml = ./user-mapping.xml;
  
  # Custom logging configuration
  logbackXml = null or path;                # Default: null
  # Example: logbackXml = ./logback.xml;
  
  # Environment variables
  extraEnvironment = {
    ENVIRONMENT = "production";             # Default: {}
    DEBUG_LEVEL = "INFO";
  };
};
```

#### Type Definitions

- **`host`**: `types.str` - Hostname or IP address
- **`port`**: `types.port` - Integer 0-65535
- **`userMappingXml`**: `types.nullOr types.path` - Path to XML file (optional)
- **`logbackXml`**: `types.nullOr types.path` - Path to XML file (optional)
- **`extraEnvironment`**: `types.attrsOf types.str` - Key-value pairs

#### Systemd Service Generated

The module creates this systemd service automatically:

```nix
systemd.services.guacamole-server = {
  description = "Apache Guacamole server (guacd)";
  wantedBy = [ "multi-user.target" ];
  after = [ "network.target" ];
  environment = {
    HOME = "/run/guacamole-server";
  } // extraEnvironment;
  serviceConfig = {
    ExecStart = "${pkgs.guacamole-server}/bin/guacd -f -b 127.0.0.1 -l 4822";
    RuntimeDirectory = "guacamole-server";
    DynamicUser = true;           # Runs as dynamic unprivileged user
    PrivateTmp = "yes";           # Isolated /tmp
    Restart = "on-failure";       # Auto-restart on crash
  };
};
```

---

### Module 2: `services.guacamole-client`

**File**: `nixos/modules/services/web-apps/guacamole-client.nix`

#### Available Options

```nix
services.guacamole-client = {
  # Enable the web application on Tomcat
  enable = true | false;                    # Default: false
  # Note: Also auto-enables services.tomcat
  
  # Package to use
  package = pkgs.guacamole-client;          # Default: pkgs.guacamole-client
  
  # Configuration (Java properties format)
  settings = {
    # Connection to guacd backend
    guacd-hostname = "localhost";
    guacd-port = 4822;
    guacd-ssl = false;
    
    # User timeout in milliseconds (idle disconnect)
    user-timeout = "300000";                # 5 minutes
    
    # Session timeout in milliseconds (total session length)
    session-timeout = "3600000";            # 1 hour
    
    # Session warning timeout in milliseconds
    session-warning-timeout = "60000";      # 1 minute warning
    
    # Features
    enable-clipboard-integration = "true";
    enable-touch-input = "true";
    enable-audio = "true";
    
    # Database authentication (if using database)
    # See DATABASE_SETUP.md for details
  };
  
  # Enable Tomcat webserver
  enableWebserver = true | false;           # Default: true
  # Set to false if running in container or custom setup
};
```

#### Type Definitions

- **`settings`**: `types.submodule { freeformType = settingsFormat.type }`
  - Accepts any Java properties key-value pairs
  - Written to `/etc/guacamole/guacamole.properties`
  - Uses `pkgs.formats.javaProperties { }` format

#### Files Generated

```
/etc/guacamole/guacamole.properties   # Generated from settings
```

---

### Module 3: `services.tomcat` (Auto-Enabled)

When `services.guacamole-client.enable = true`, Tomcat is automatically configured:

```nix
services.tomcat = {
  enable = true;                            # Auto-enabled
  port = 8080;                              # Default Tomcat port
  webapps = [ pkgs.guacamole-client ];      # Auto-added
  jvmOpts = [ "-Xms256m" "-Xmx512m" ];      # Default JVM options
};
```

**Access**: `http://localhost:8080/guacamole/`

---

## User Authentication Methods

### Method 1: File-Based (user-mapping.xml)

✅ **Recommended for**: Simple deployments, testing, single-user

```nix
{
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4822;
    userMappingXml = ./user-mapping.xml;    # ← This is the correct option
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

**Example `user-mapping.xml`**:

```xml
<user-mapping>
  <authorize username="user1" password="password1">
    <connection name="Desktop">
      <protocol>rdp</protocol>
      <param name="hostname">192.168.1.100</param>
      <param name="port">3389</param>
      <param name="username">admin</param>
      <param name="password">rdp-password</param>
    </connection>
  </authorize>
</user-mapping>
```

### Method 2: Database-Based (PostgreSQL/MySQL)

✅ **Recommended for**: Production, multiple users, centralized management

```nix
{
  # Database service
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    # Database initialization handled separately
    # See DATABASE_SETUP.md
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
      # Connection to guacd
      guacd-hostname = "localhost";
      guacd-port = 4822;
      
      # PostgreSQL database authentication
      postgresql-hostname = "localhost";
      postgresql-port = 5432;
      postgresql-database = "guacamole";
      postgresql-username = "guacamole";
      postgresql-password = "guacamole";  # Use agenix for secrets!
    };
  };

  # Ensure guacamole-client waits for database
  systemd.services.guacamole-client = {
    after = [ "postgresql.service" ];
  };
}
```

### Method 3: No Authentication (Development Only)

⚠️ **Not recommended for production**

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
  # No authentication configured - anyone can access
}
```

---

## Proper Syntax Examples

### Example 1: Minimal Configuration

```nix
# modules/nixos/hosts/my-guacamole/default.nix

{ config, lib, pkgs, ... }:

{
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
    };
  };

  # Open firewall for web access
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
```

### Example 2: With User Mapping File

```nix
# modules/nixos/hosts/my-guacamole/default.nix

{ config, lib, pkgs, ... }:

let
  userMappingXml = pkgs.writeText "user-mapping.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <user-mapping>
      <authorize username="admin" password="admin123">
        <connection name="RDP Server">
          <protocol>rdp</protocol>
          <param name="hostname">192.168.1.100</param>
          <param name="port">3389</param>
          <param name="username">rdp-user</param>
          <param name="password">rdp-password</param>
        </connection>
      </authorize>
    </user-mapping>
  '';
in
{
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4822;
    userMappingXml = userMappingXml;        # ← Correct option
  };

  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
```

### Example 3: With Reverse Proxy (Caddy)

```nix
{
  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";  # Local only - reverse proxy handles external
    port = 4822;
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
    email = "admin@example.com";  # For Let's Encrypt
    virtualHosts."guac.example.com" = {
      extraConfig = ''
        reverse_proxy localhost:8080 {
          flush_interval -1
          header_up X-Forwarded-For {http.request.remote.host}
          header_up X-Forwarded-Proto {http.request.scheme}
        }
      '';
    };
  };

  # Open firewall for HTTPS only
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

## Required Dependencies and Services

### Core Dependencies (Automatic)

When you enable Guacamole, these are automatically configured:

| Dependency | Enabled By | Purpose |
|-----------|-----------|---------|
| `services.tomcat` | `guacamole-client.enableWebserver = true` | Web server hosting |
| `pkgs.guacamole-server` | `guacamole-server.enable = true` | Backend daemon |
| `pkgs.guacamole-client` | `guacamole-client.enable = true` | Web application |

### Optional Dependencies

Add these as needed:

```nix
{
  # For database-backed authentication
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
  };
  
  # Or MySQL instead
  services.mysql = {
    enable = true;
    package = pkgs.mysql80;
  };

  # For HTTPS termination
  services.caddy = {
    enable = true;
  };

  # For systemd socket activation (optional)
  systemd.sockets.guacamole-server = {
    # Advanced configuration
  };
}
```

---

## Network Configuration

### Default Ports

| Service | Port | Description |
|---------|------|-------------|
| guacd (server) | 4822 | Backend daemon (local communication) |
| Tomcat | 8080 | Web application HTTP |
| HTTPS (reverse proxy) | 443 | Secure web access |
| HTTP (reverse proxy) | 80 | HTTP redirect to HTTPS |

### Network Binding

```nix
# Local only (most secure for single-server setup)
services.guacamole-server = {
  host = "127.0.0.1";  # Only localhost can connect
  port = 4822;
};

# OR all interfaces (for distributed setup - use with caution!)
services.guacamole-server = {
  host = "0.0.0.0";    # All network interfaces
  port = 4822;
};

# OR specific interface
services.guacamole-server = {
  host = "192.168.1.100";  # Specific IP address
  port = 4822;
};
```

### Firewall Configuration

```nix
{
  # For reverse proxy setup (web access only)
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  
  # For direct Tomcat access (no reverse proxy)
  networking.firewall.allowedTCPPorts = [ 8080 ];
  
  # For network guacd access (not recommended!)
  networking.firewall.allowedTCPPorts = [ 4822 ];
}
```

---

## File Locations

### Generated Configuration Files

```
/etc/guacamole/
├── guacamole.properties        # Main config (from settings)
├── user-mapping.xml            # User auth (if userMappingXml set)
└── logback.xml                 # Logging config (if logbackXml set)

/run/guacamole-server/          # Runtime directory (guacd only)
/var/log/tomcat/                # Tomcat logs
```

### Module Paths in nixpkgs

```
nixos/modules/services/web-apps/
├── guacamole-server.nix        # services.guacamole-server
├── guacamole-client.nix        # services.guacamole-client
└── tomcat.nix                  # services.tomcat

nixos/tests/
└── guacamole-server.nix        # Basic test

pkgs/by-name/gu/
├── guacamole-server/           # Package
└── guacamole-client/           # Package
```

---

## Summary Table

| Aspect | Option | Location | Type | Default |
|--------|--------|----------|------|---------|
| **Enable server** | `enable` | `services.guacamole-server` | bool | false |
| **Server host** | `host` | `services.guacamole-server` | str | "127.0.0.1" |
| **Server port** | `port` | `services.guacamole-server` | port | 4822 |
| **User mapping** | `userMappingXml` | `services.guacamole-server` | path? | null |
| **Logging config** | `logbackXml` | `services.guacamole-server` | path? | null |
| **Environment vars** | `extraEnvironment` | `services.guacamole-server` | attrs | {} |
| **Enable client** | `enable` | `services.guacamole-client` | bool | false |
| **Client settings** | `settings` | `services.guacamole-client` | attrs | `{guacd-hostname = "localhost"; guacd-port = 4822;}` |
| **Enable webserver** | `enableWebserver` | `services.guacamole-client` | bool | true |

---

## Key Points to Remember

✅ **Correct**:
- `services.guacamole-server.userMappingXml` - For file-based auth
- `services.guacamole-client.settings` - For Java properties config
- Database config in `settings` (e.g., `postgresql-hostname`, `postgresql-port`)

❌ **Incorrect**:
- `services.guacamole-client.userMappingXml` - This option does NOT exist
- Trying to set auth via client module - Auth is server-side or database

---

## Sources

- **nixpkgs commit**: Verified against master branch
- **Modules**:
  - `nixos/modules/services/web-apps/guacamole-server.nix`
  - `nixos/modules/services/web-apps/guacamole-client.nix`
- **Test**: `nixos/tests/guacamole-server.nix`
- **Versions**: guacamole-server v1.6.0, guacamole-client v1.6.0

