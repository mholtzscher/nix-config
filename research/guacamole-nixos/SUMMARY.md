# Apache Guacamole on NixOS - Research Summary

## Executive Summary

Apache Guacamole has **full native support** in NixOS through dedicated service modules (`services.guacamole-server` and `services.guacamole-client`). A minimal working configuration requires just 6 lines of Nix code and can be deployed and accessed in under 5 minutes.

## Key Findings

### ✅ What Works Well

1. **Excellent NixOS Integration**
   - Native modules with all necessary options
   - Automatic Tomcat integration
   - Systemd service management
   - Configuration file generation

2. **Multiple Authentication Options**
   - Simple file-based (user-mapping.xml) for quick setup
   - Database-backed (PostgreSQL/MySQL) for production
   - Extension support for LDAP, OIDC/OAuth

3. **Flexible Deployment**
   - Minimal setup: ~10 lines of Nix
   - Production setup: ~50-100 lines with database and proxy
   - Scalable: Database sharing across multiple instances

4. **Supported Protocols**
   - RDP (Windows Remote Desktop)
   - VNC (Virtual Network Computing)
   - SSH (Secure Shell)
   - Telnet

5. **Active Maintenance**
   - Version 1.6.0 available in nixpkgs
   - NixOS tests verify functionality
   - Community examples available

### ⚠️ Important Considerations

1. **Default Credentials**
   - Username: `guacadmin`
   - Password: `guacadmin`
   - **Must change immediately** on first login

2. **Configuration Files**
   - All config in /etc (read-only)
   - Regenerated on every rebuild (no persistence of manual changes)
   - Use version control (Git) for configuration

3. **Passwords in user-mapping.xml**
   - Stored as plaintext in NixOS configuration
   - Use database + secrets management for production
   - Consider agenix for secret management

4. **Network Configuration**
   - guacd binds to localhost (127.0.0.1) by default
   - Tomcat also listens locally
   - Requires reverse proxy for remote access
   - Firewall rules needed for HTTPS ports (80, 443)

## Core Configuration

### Absolute Minimum

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
}
```

**Result**: Access at `http://localhost:8080/guacamole`

### With Reverse Proxy (Recommended)

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
  
  services.caddy = {
    enable = true;
    email = "admin@example.com";
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

**Result**: Access at `https://guacamole.example.com` with automatic HTTPS

### Production with Database

```nix
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
  };

  services.guacamole-server.enable = true;
  
  services.guacamole-client = {
    enable = true;
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;
      postgresql-hostname = "localhost";
      postgresql-database = "guacamole";
      postgresql-username = "guacamole";
      postgresql-password = "...";  # Use agenix!
    };
  };

  services.caddy = {
    enable = true;
    email = "admin@example.com";
    virtualHosts."guacamole.example.com" = {
      extraConfig = ''reverse_proxy localhost:8080 { flush_interval -1 }'';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

## Architecture Summary

```
Internet (User)
    ↓ HTTPS:443
Reverse Proxy (Caddy/Nginx)
    ↓ HTTP:8080
Tomcat (guacamole-client)
    ↓ TCP:4822
guacd (guacamole-server)
    ↓
RDP/VNC/SSH/Telnet Servers
```

### Service Dependencies

- **guacamole-server**: Depends on network target, runs as dynamic user
- **guacamole-client**: Enables tomcat, depends on network target
- **Tomcat**: Auto-enabled when guacamole-client enabled
- **Reverse Proxy**: Optional, connects to localhost:8080
- **Database**: Optional, enables centralized user/connection management

## Configuration Deployment Workflow

### 1. Write Configuration

Create `modules/nixos/hosts/your-host/guacamole.nix`:

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
}
```

### 2. Validate

```bash
nix flake check
sudo nixos-rebuild build --flake .
```

### 3. Apply

```bash
sudo nixos-rebuild switch --flake .
```

### 4. Verify

```bash
systemctl status guacamole-server
systemctl status tomcat
systemctl status caddy  # if proxy enabled
```

### 5. Test Access

- Open browser: `http://localhost:8080/guacamole`
- Login: `guacadmin` / `guacadmin`
- Create test connection

### 6. Harden

- Change default password
- Add reverse proxy for HTTPS
- Configure authentication (database or SSO)
- Set up firewall rules
- Enable audit logging

## NixOS Module Reference

### services.guacamole-server

| Option | Default | Type | Purpose |
|--------|---------|------|---------|
| `enable` | false | bool | Enable guacd daemon |
| `host` | "127.0.0.1" | string | Bind address |
| `port` | 4822 | port | Listen port |
| `userMappingXml` | null | path | User/connection file |
| `logbackXml` | null | path | Logging configuration |
| `extraEnvironment` | {} | attrs | Environment variables |

### services.guacamole-client

| Option | Default | Type | Purpose |
|--------|---------|------|---------|
| `enable` | false | bool | Enable web client |
| `package` | pkgs.guacamole-client | package | Client package |
| `settings` | {} | attrs | guacamole.properties |
| `enableWebserver` | true | bool | Enable Tomcat |

### Key Settings for guacamole-client.settings

```nix
{
  # Required: guacd connection
  guacd-hostname = "localhost";
  guacd-port = 4822;
  
  # Optional: database (one of postgresql or mysql)
  postgresql-hostname = "localhost";
  postgresql-port = 5432;
  postgresql-database = "guacamole";
  postgresql-username = "guacamole";
  postgresql-password = "...";
  
  # Optional: session management
  user-timeout = "300000";        # 5 minutes (ms)
  session-timeout = "3600000";    # 1 hour (ms)
  session-warning-timeout = "60000";
  
  # Optional: features
  enable-clipboard-integration = "true";
  enable-touch-input = "true";
  enable-audio = "true";
}
```

## Reverse Proxy Options

### Caddy (Recommended - Easiest)

Automatic HTTPS with Let's Encrypt:

```nix
services.caddy = {
  enable = true;
  email = "admin@example.com";
  virtualHosts."guacamole.example.com" = {
    extraConfig = ''
      reverse_proxy localhost:8080 {
        flush_interval -1
      }
    '';
  };
};
networking.firewall.allowedTCPPorts = [ 80 443 ];
```

### Nginx (More Control)

```nix
services.nginx = {
  enable = true;
  virtualHosts."guacamole.example.com" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_read_timeout 600s;
      '';
    };
  };
};
security.acme = {
  acceptTerms = true;
  defaults.email = "admin@example.com";
};
networking.firewall.allowedTCPPorts = [ 80 443 ];
```

### Apache (Enterprise)

```nix
services.apache2 = {
  enable = true;
  mods = [ "proxy" "proxy_http" "proxy_wstunnel" "rewrite" "ssl" ];
  virtualHosts."guacamole.example.com" = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      ProxyPreserveHost On
      ProxyPass / http://localhost:8080/ nocanon
      ProxyPassReverse / http://localhost:8080/
    '';
  };
};
```

## Database Setup (Production)

### PostgreSQL (Recommended)

1. Enable PostgreSQL:
```nix
services.postgresql = {
  enable = true;
  package = pkgs.postgresql_15;
};
```

2. Initialize schema on activation (see DATABASE_SETUP.md)

3. Configure Guacamole:
```nix
services.guacamole-client.settings = {
  postgresql-hostname = "localhost";
  postgresql-database = "guacamole";
  postgresql-username = "guacamole";
  postgresql-password = "...";  # Use agenix!
};
```

### MySQL / MariaDB

```nix
services.mysql = {
  enable = true;
  package = pkgs.mysql80;
};

services.guacamole-client.settings = {
  mysql-hostname = "localhost";
  mysql-database = "guacamole";
  mysql-username = "guacamole";
  mysql-password = "...";
};
```

## Security Best Practices

### 1. Credentials
- ✅ Use database with strong passwords
- ✅ Use agenix or sops-nix for secrets
- ❌ Don't store passwords in Nix store
- ❌ Don't use default credentials in production

### 2. Network
- ✅ Keep guacd on localhost only (127.0.0.1)
- ✅ Use HTTPS via reverse proxy
- ✅ Configure strict firewall rules
- ❌ Don't expose guacd port (4822) to internet

### 3. Authentication
- ✅ Use database with OIDC/LDAP for enterprise
- ✅ Enable audit logging
- ✅ Regular security updates
- ❌ Don't use user-mapping.xml with plaintext passwords in production

### 4. Backend Connections
- ✅ Use SSH keys for terminal access
- ✅ Verify RDP/VNC server certificates
- ✅ Use encrypted connections
- ❌ Don't embed credentials in user-mapping.xml

## Troubleshooting Quick Reference

| Issue | Symptom | Check | Fix |
|-------|---------|-------|-----|
| Cannot access | Connection refused on :8080 | `systemctl status tomcat` | Start services, open firewall |
| Backend unreachable | "Connection Failed" after login | Backend reachable? | Check IP/port/firewall |
| WebSocket fails | Disconnect via proxy | Reverse proxy config | Set `flush_interval -1` |
| Auth fails | Login error on user-mapping.xml | XML valid? | Fix XML syntax |
| DB connection fails | "Authentication failed" | DB running? | Start PostgreSQL/MySQL |
| Timeout disconnect | Disconnects after N minutes | Timeout settings | Increase user-timeout |

See TROUBLESHOOTING.md for detailed solutions.

## Documentation Structure

This research includes 9 comprehensive documents:

1. **README.md** - Overview and key findings (2 KB)
2. **QUICK_START.md** - Basic setup examples (4 KB)
3. **NIXOS_OPTIONS.md** - Complete module reference (8 KB)
4. **ARCHITECTURE.md** - System components and design (10 KB)
5. **DATABASE_SETUP.md** - Production database guide (9 KB)
6. **PROXY_CONFIG.md** - Reverse proxy setup (11 KB)
7. **EXAMPLES.md** - Real-world configurations (12 KB)
8. **TROUBLESHOOTING.md** - Common issues and solutions (13 KB)
9. **INDEX.md** - Navigation and overview (11 KB)

**Total**: ~80 KB of comprehensive documentation

## Recommended Reading Order

**For Quick Setup** (5-15 min):
1. README.md (overview)
2. QUICK_START.md (examples 1 & 2)
3. Deploy and test

**For Production** (30-60 min):
1. ARCHITECTURE.md (understand design)
2. NIXOS_OPTIONS.md (configuration details)
3. DATABASE_SETUP.md (production-grade auth)
4. PROXY_CONFIG.md (HTTPS setup)
5. EXAMPLES.md (copy-paste templates)

**For Troubleshooting** (as needed):
1. TROUBLESHOOTING.md (problem-solving guide)
2. ARCHITECTURE.md (reference)
3. INDEX.md (resource links)

## Next Steps for Your Configuration

### 1. Create Module
```bash
mkdir -p modules/nixos/hosts/your-host/guacamole
touch modules/nixos/hosts/your-host/guacamole/default.nix
```

### 2. Copy Basic Configuration
From QUICK_START.md Example 1 or EXAMPLES.md

### 3. Test
```bash
nix flake check
sudo nixos-rebuild build --flake .
```

### 4. Deploy
```bash
sudo nixos-rebuild switch --flake .
```

### 5. Enhance
Add reverse proxy, database, authentication as needed

## Resources

- **Apache Guacamole**: https://guacamole.apache.org/
- **NixOS Manual**: https://nixos.org/manual/nixos/
- **NixOS Packages**: https://search.nixos.org/packages
- **NixOS Options**: https://search.nixos.org/options
- **NixOS Discourse**: https://discourse.nixos.org/

## Conclusion

Apache Guacamole is well-supported in NixOS with minimal configuration overhead. A production-grade deployment with HTTPS, database authentication, and multiple connections can be accomplished in 50-100 lines of Nix code. The combination of NixOS's declarative configuration and Guacamole's flexible architecture makes it an excellent choice for remote desktop gateway deployments.
