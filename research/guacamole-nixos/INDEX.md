# Apache Guacamole on NixOS - Research Index

## Document Overview

This research provides comprehensive documentation for configuring Apache Guacamole on NixOS, from basic setup to production deployments.

### Quick Navigation

| Document | Purpose | Best For |
|----------|---------|----------|
| **README.md** | Overview and key findings | Starting point, understanding scope |
| **QUICK_START.md** | Basic setup examples | Getting started in 5 minutes |
| **NIXOS_OPTIONS.md** | Complete NixOS module reference | Configuration details and options |
| **ARCHITECTURE.md** | System components and data flow | Understanding how it works |
| **DATABASE_SETUP.md** | Production database configuration | PostgreSQL, MySQL, schemas, credentials |
| **PROXY_CONFIG.md** | Reverse proxy setup (Caddy, Nginx, Apache) | HTTPS, multiple paths, SSL/TLS |
| **EXAMPLES.md** | Real-world configuration examples | Copy-paste templates |
| **TROUBLESHOOTING.md** | Common issues and solutions | Fixing problems |

## Key Findings Summary

### NixOS Guacamole Support

✅ **Full native support** for Guacamole in NixOS via:
- `services.guacamole-server` - Backend daemon (guacd)
- `services.guacamole-client` - Web application (Tomcat)

**Versions (from nixpkgs)**:
- guacamole-server: 1.6.0 (unstable-2025-06-29)
- guacamole-client: 1.6.0
- Supports: RDP, VNC, SSH, Telnet

### Required Services

| Service | Role | Auto-enabled |
|---------|------|--------------|
| guacamole-server | Protocol handler daemon | No, explicit enable |
| guacamole-client | Web UI and management | No, explicit enable |
| tomcat | Web application container | Yes, if client enabled |
| (Optional) Reverse proxy | HTTPS/SSL, path routing | No, use Caddy/Nginx/Apache |
| (Optional) Database | User/connection management | No, use PostgreSQL/MySQL |

### Default Configuration

```nix
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
```

### Access Points

| Setup | URL | Port | Notes |
|-------|-----|------|-------|
| Direct | `http://localhost:8080/guacamole` | 8080 | Local only |
| Via Caddy | `https://guacamole.example.com` | 443 | HTTPS, auto certs |
| Via Nginx | `https://guacamole.example.com` | 443 | HTTPS, manual certs |
| At path | `https://example.com/guacamole/` | 443 | Multiple services |

## Common Use Cases

### 1. Simple Testing Setup
- **Time**: 5 minutes
- **Complexity**: Low
- **Files**: QUICK_START.md (Example 1)
- **Components**: guacamole-server + guacamole-client
- **Authentication**: user-mapping.xml

```bash
# Access: http://localhost:8080/guacamole
# Credentials: guacadmin / guacadmin (change immediately!)
```

### 2. Home Lab with Multiple Connections
- **Time**: 15 minutes
- **Complexity**: Low-Medium
- **Files**: QUICK_START.md (Example 2), EXAMPLES.md
- **Components**: guacamole + user-mapping.xml
- **Authentication**: File-based

```bash
# Access: http://localhost:8080/guacamole
# Multiple RDP/VNC/SSH/Telnet connections configured
```

### 3. Production with HTTPS
- **Time**: 30 minutes
- **Complexity**: Medium
- **Files**: QUICK_START.md (Example 3), PROXY_CONFIG.md
- **Components**: guacamole + Caddy/Nginx + firewall rules
- **Authentication**: File-based or database

```bash
# Access: https://guacamole.example.com
# Automatic HTTPS with Let's Encrypt
```

### 4. Enterprise Database Setup
- **Time**: 1-2 hours
- **Complexity**: High
- **Files**: DATABASE_SETUP.md, EXAMPLES.md (Example 2)
- **Components**: guacamole + PostgreSQL + Caddy + firewall
- **Authentication**: JDBC database, extensible to LDAP/OIDC

```bash
# Access: https://guacamole.example.com
# Centralized user/connection management
# Audit logging and advanced features
```

### 5. Container-Based Setup
- **Time**: 20 minutes
- **Complexity**: Medium
- **Files**: EXAMPLES.md (Example 4)
- **Components**: Podman/Docker containers + guacamole-client on host
- **Authentication**: Database (PostgreSQL in container)

```bash
# guacd and PostgreSQL run in containers
# Guacamole client runs as systemd service
```

## NixOS Configuration Workflow

### Step 1: Enable Minimal Services

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
}
```

### Step 2: Validate Configuration

```bash
nix flake check
sudo nixos-rebuild build --flake .
```

### Step 3: Apply Configuration

```bash
sudo nixos-rebuild switch --flake .
```

### Step 4: Verify Services

```bash
systemctl status guacamole-server
systemctl status tomcat
journalctl -u guacamole-server -n 50
```

### Step 5: Access & Test

- Open browser: `http://localhost:8080/guacamole`
- Default credentials: `guacadmin` / `guacadmin`
- Test connection to backend service

### Step 6: Harden Configuration

- Change default credentials
- Add reverse proxy for HTTPS
- Configure firewall
- Set up database for production
- Enable audit logging

## Important Configuration Options

### guacamole-server Options

| Option | Default | Purpose |
|--------|---------|---------|
| `enable` | false | Enable guacd daemon |
| `host` | "127.0.0.1" | Bind address |
| `port` | 4822 | Listen port |
| `userMappingXml` | null | User/connection file |
| `extraEnvironment` | {} | Environment variables |

### guacamole-client Options

| Option | Default | Purpose |
|--------|---------|---------|
| `enable` | false | Enable web client |
| `settings` | {} | guacamole.properties config |
| `enableWebserver` | true | Enable Tomcat |

### Key Settings for guacamole-client

```nix
settings = {
  # Connection to guacd
  guacd-hostname = "localhost";
  guacd-port = 4822;
  
  # Database (optional)
  postgresql-hostname = "localhost";
  postgresql-database = "guacamole";
  
  # Timeouts (in milliseconds)
  user-timeout = "300000";        # 5 minutes
  session-timeout = "3600000";    # 1 hour
  
  # Features
  enable-clipboard-integration = "true";
  enable-touch-input = "true";
};
```

## Security Considerations

### Default Credentials
- **Username**: `guacadmin`
- **Password**: `guacadmin`
- ⚠️ **Change immediately** on first login

### Authentication Methods (Ranked by Security)

1. **Database + OIDC** (Best) - Centralized, SSO-capable
2. **Database + LDAP** - Enterprise integration
3. **Database + username/password** - Individual passwords
4. **Database only** (JDBC) - Default DB users
5. **user-mapping.xml** - Plaintext passwords (development only)

### Network Security

- Keep guacd port (4822) local only: `host = "127.0.0.1"`
- Use HTTPS via reverse proxy for web access
- Configure firewall: only allow necessary ports
- Use strong passwords and SSH keys
- Regular backups of configuration and database

## File Locations

### NixOS Modules

- `nixos/modules/services/web-apps/guacamole-server.nix`
- `nixos/modules/services/web-apps/guacamole-client.nix`
- Test: `nixos/tests/guacamole-server.nix`

### Generated Files (at runtime)

- `/etc/guacamole/guacamole.properties` - Auto-generated from settings
- `/etc/guacamole/user-mapping.xml` - Provided via config
- `/etc/guacamole/logback.xml` - Optional logging config
- `/run/guacamole-server/` - Runtime directory
- `/run/tomcat/` - Tomcat runtime

### Configuration Provided

- User configuration can be provided as separate files
- All files mounted as read-only in /etc
- Regenerated on each NixOS rebuild

## Typical Deployment Scenarios

### Scenario 1: Developer Testing
```
Browser → guacamole-client (localhost:8080) → guacd → RDP/VNC
Auth: user-mapping.xml
```

### Scenario 2: Small Office
```
Browser → guacamole-client (private network) → guacd → Remote desktops
Auth: PostgreSQL with local users
```

### Scenario 3: Enterprise
```
Browser → Reverse Proxy (HTTPS) → guacamole-client → guacd → Backends
Auth: LDAP/OIDC + PostgreSQL + Audit logging
Scale: Load balanced, multiple instances
```

### Scenario 4: Hybrid Cloud
```
Browser → CDN/WAF → Reverse Proxy → guacamole-client → guacd → Mixed Backends
Auth: OAuth/OIDC + PostgreSQL
Scale: Horizontal scaling, geo-distributed
```

## Troubleshooting Quick Reference

| Problem | Check | Fix |
|---------|-------|-----|
| Cannot access :8080 | guacamole-server, firewall | Start service, open port |
| Cannot connect to RDP | guacd port 4822, credentials | Check backend reachability |
| WebSocket connection fails | Reverse proxy buffering | Set flush_interval -1 |
| Authentication fails | user-mapping.xml syntax | Fix XML, rebuild |
| Database connection error | postgresql/mysql running | Start DB service |
| HTTPS cert issues | ACME validation | Check port 80 open, DNS valid |

See **TROUBLESHOOTING.md** for detailed solutions.

## Resources

### Official Documentation
- [Apache Guacamole](https://guacamole.apache.org/)
- [Guacamole Configuration Guide](https://guacamole.apache.org/doc/gug/configuring-guacamole.html)
- [NixOS Manual](https://nixos.org/manual/nixos/)

### NixOS Packages
- [guacamole-server](https://search.nixos.org/packages)
- [guacamole-client](https://search.nixos.org/packages)

### Community
- [NixOS Discourse](https://discourse.nixos.org/)
- [GitHub Issues](https://github.com/NixOS/nixpkgs/issues)

### Related Modules
- [Tomcat (services.tomcat)](https://search.nixos.org/options)
- [PostgreSQL (services.postgresql)](https://search.nixos.org/options)
- [MySQL (services.mysql)](https://search.nixos.org/options)
- [Caddy (services.caddy)](https://search.nixos.org/options)
- [Nginx (services.nginx)](https://search.nixos.org/options)

## Version Information

**Research Date**: November 2024

**NixOS Versions Covered**:
- NixOS unstable (latest)
- NixOS 24.05+

**Package Versions**:
- guacamole-server: 1.6.0 (unstable)
- guacamole-client: 1.6.0
- Tomcat: 9.0+
- PostgreSQL: 13+
- MySQL: 8.0 / MariaDB 10.5+

**Protocols Supported**:
- RDP (Windows Remote Desktop)
- VNC (Virtual Network Computing)
- SSH (Secure Shell)
- Telnet

## Next Steps

1. **For beginners**: Start with QUICK_START.md
2. **For configuration details**: See NIXOS_OPTIONS.md
3. **For production setup**: Follow DATABASE_SETUP.md and PROXY_CONFIG.md
4. **For copy-paste examples**: Check EXAMPLES.md
5. **For issues**: Consult TROUBLESHOOTING.md
6. **For architecture understanding**: Read ARCHITECTURE.md
