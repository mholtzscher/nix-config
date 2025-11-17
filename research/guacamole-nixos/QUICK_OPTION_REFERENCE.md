# NixOS Guacamole Options - Quick Reference

## The Key Error You Found

❌ **This doesn't exist**:
```nix
services.guacamole-client.userMappingXml = ./user-mapping.xml;  # WRONG!
```

✅ **This is correct**:
```nix
services.guacamole-server.userMappingXml = ./user-mapping.xml;  # RIGHT!
```

---

## Complete Option Reference

### `services.guacamole-server.*`

| Option | Type | Default | Notes |
|--------|------|---------|-------|
| `enable` | bool | `false` | Starts the guacd daemon |
| `package` | package | `pkgs.guacamole-server` | v1.6.0 |
| `host` | string | `"127.0.0.1"` | Binding address |
| `port` | int(0-65535) | `4822` | Listening port |
| `userMappingXml` | path? | `null` | File-based auth ← **USE THIS** |
| `logbackXml` | path? | `null` | Custom logging config |
| `extraEnvironment` | attrs | `{}` | Environment variables |

### `services.guacamole-client.*`

| Option | Type | Default | Notes |
|--------|------|---------|-------|
| `enable` | bool | `false` | Enables Tomcat web app |
| `package` | package | `pkgs.guacamole-client` | v1.6.0 |
| `settings` | attrs | See below | Java properties config |
| `enableWebserver` | bool | `true` | Enable Tomcat hosting |

#### Default `services.guacamole-client.settings`

```nix
{
  guacd-hostname = "localhost";
  guacd-port = 4822;
}
```

#### Common `settings` keys

```nix
settings = {
  # guacd connection
  guacd-hostname = "localhost";
  guacd-port = 4822;
  guacd-ssl = "false";
  
  # Timeouts (milliseconds)
  user-timeout = "300000";           # 5 min idle disconnect
  session-timeout = "3600000";       # 1 hour max session
  session-warning-timeout = "60000"; # 1 min warning
  
  # Database (PostgreSQL example)
  postgresql-hostname = "localhost";
  postgresql-port = "5432";
  postgresql-database = "guacamole";
  postgresql-username = "guacamole";
  postgresql-password = "password";
  
  # MySQL equivalent
  mysql-hostname = "localhost";
  mysql-port = "3306";
  mysql-database = "guacamole";
  mysql-username = "guacamole";
  mysql-password = "password";
  
  # Features
  enable-clipboard-integration = "true";
  enable-touch-input = "true";
  enable-audio = "true";
};
```

---

## Three Working Examples

### 1. Minimal (Default)

```nix
services.guacamole-server.enable = true;
services.guacamole-client.enable = true;
```

### 2. With File-Based Auth

```nix
services.guacamole-server = {
  enable = true;
  userMappingXml = ./user-mapping.xml;  # ← This option!
};

services.guacamole-client.enable = true;
```

### 3. With Database

```nix
services.postgresql.enable = true;

services.guacamole-server.enable = true;

services.guacamole-client = {
  enable = true;
  settings = {
    guacd-hostname = "localhost";
    guacd-port = 4822;
    postgresql-hostname = "localhost";
    postgresql-port = "5432";
    postgresql-database = "guacamole";
    postgresql-username = "guacamole";
    postgresql-password = "password";
  };
};
```

---

## Authentication Methods Summary

| Method | Option | Location | Use Case |
|--------|--------|----------|----------|
| File-based | `userMappingXml` | `services.guacamole-server` | Simple, testing |
| Database | `settings.*` | `services.guacamole-client` | Production |
| None | (omit both) | (none) | Development only |

---

## Common Mistakes

| ❌ Wrong | ✅ Right | Why |
|---------|---------|-----|
| `guacamole-client.userMappingXml` | `guacamole-server.userMappingXml` | Auth is server-side |
| `settings.userMappingXml = ...` | `userMappingXml = ...` (in server) | Option location is wrong |
| `user-mapping-xml` | `userMappingXml` | Camel case, not hyphenated |
| Setting auth in client | Setting in server or settings | Architectural mismatch |

---

## Verify Your Configuration

```bash
# Check syntax
nix flake check

# Build configuration (don't apply yet!)
nb  # darwin-rebuild build --flake .

# Only then:
nup # darwin-rebuild switch --flake . (when ready to apply)
```

