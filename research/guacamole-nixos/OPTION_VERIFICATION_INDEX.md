# NixOS Guacamole Options - Complete Verification Index

## 🎯 Quick Answer

| Question | Answer | Reference |
|----------|--------|-----------|
| Does `services.guacamole-client.userMappingXml` exist? | ❌ No | `VERIFICATION_SUMMARY.md` |
| Does `services.guacamole-server.userMappingXml` exist? | ✅ Yes | `CORRECT_NIXOS_OPTIONS.md` |
| How do I set user authentication? | Use `userMappingXml` in **server** or database in **client** settings | `QUICK_OPTION_REFERENCE.md` |
| Where are the actual module files? | `nixos/modules/services/web-apps/` | `NIXPKGS_SOURCE_CODE.md` |

---

## 📚 Document Guide

### For Quick Lookup
👉 **`QUICK_OPTION_REFERENCE.md`** (3 min read)
- All options in table format
- Common mistakes
- 3 working examples
- Best for: "I need the option now"

### For Complete Reference
👉 **`CORRECT_NIXOS_OPTIONS.md`** (10 min read)
- Every option explained
- Type definitions and defaults
- Authentication methods (3 types)
- Network configuration
- File locations
- Best for: "I need to understand everything"

### For Verification
👉 **`VERIFICATION_SUMMARY.md`** (5 min read)
- Your finding confirmed
- Why the separation exists
- Architecture diagram
- Error messages
- Best for: "I need proof this is correct"

### For Source Code
👉 **`NIXPKGS_SOURCE_CODE.md`** (8 min read)
- Actual nixpkgs source code
- Type system explained
- Config file generation
- Best for: "I want to see the code"

---

## 🔍 What You Found

**Your Discovery**: The option `services.guacamole-client.userMappingXml` doesn't exist

### Why This Matters

This error would cause your NixOS configuration to fail:

```
❌ Error during build:
error: The option `services.guacamole-client.userMappingXml' does not exist.
```

### The Fix

Move `userMappingXml` to the correct module:

```nix
# ❌ WRONG
services.guacamole-client = {
  userMappingXml = ./user-mapping.xml;
};

# ✅ CORRECT
services.guacamole-server = {
  userMappingXml = ./user-mapping.xml;
};
```

---

## 📋 Complete Option List

### `services.guacamole-server` ← Authentication options here

```nix
services.guacamole-server = {
  enable = true | false;                           # Start daemon
  package = pkgs.guacamole-server;                 # Which version
  host = "127.0.0.1" | "0.0.0.0" | "192.168.1.1"; # Binding address
  port = 4822;                                     # Listening port
  
  userMappingXml = null | /path/to/file;           # ← FILE-BASED AUTH
  logbackXml = null | /path/to/file;               # Logging config
  
  extraEnvironment = {
    ENVIRONMENT = "production";
    DEBUG_LEVEL = "INFO";
  };
};
```

### `services.guacamole-client` ← Database/settings options here

```nix
services.guacamole-client = {
  enable = true | false;                           # Enable web app
  package = pkgs.guacamole-client;                 # Which version
  
  settings = {
    # Basic connection
    guacd-hostname = "localhost";
    guacd-port = 4822;
    
    # Database authentication ← DB-BASED AUTH
    postgresql-hostname = "localhost";
    postgresql-port = "5432";
    postgresql-database = "guacamole";
    postgresql-username = "guacamole";
    postgresql-password = "password";
    
    # Or MySQL
    mysql-hostname = "localhost";
    mysql-port = "3306";
    # ...similar to PostgreSQL
  };
  
  enableWebserver = true | false;                  # Enable Tomcat
};
```

---

## 🔧 Authentication Methods

### 1️⃣ File-Based (Simple)

**Option Location**: `services.guacamole-server.userMappingXml`

```nix
{
  services.guacamole-server = {
    enable = true;
    userMappingXml = ./user-mapping.xml;  # ← Use HERE
  };

  services.guacamole-client.enable = true;
}
```

**Best for**: Testing, single users, simple deployments

### 2️⃣ Database-Based (Production)

**Option Location**: `services.guacamole-client.settings.*`

```nix
{
  services.postgresql.enable = true;

  services.guacamole-server.enable = true;

  services.guacamole-client = {
    enable = true;
    settings = {
      postgresql-hostname = "localhost";
      postgresql-port = "5432";
      postgresql-database = "guacamole";
      postgresql-username = "guacamole";
      postgresql-password = "password";  # Use agenix!
    };
  };
}
```

**Best for**: Production, multiple users, centralized management

### 3️⃣ No Authentication (Dev Only)

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
  # Anyone can access - dev only!
}
```

---

## 🏗️ Architecture Explanation

**Why authentication goes in the server module:**

```
User connects to web interface (localhost:8080)
                ↓
        guacamole-client (Tomcat)
        • Serves web UI
        • Reads settings from guacamole.properties
        • Configured via: settings = { ... }
                ↓
        Connects to backend (port 4822)
        guacd protocol
                ↓
        guacamole-server (guacd daemon)
        • Handles RDP/VNC/SSH/Telnet
        • Authenticates users
        • Reads user mappings from user-mapping.xml
        • Configured via: userMappingXml = ...
                ↓
        Connects to actual desktop/server
        RDP on port 3389, VNC on port 5900, etc.
```

**Key insight**: User authentication happens in the backend (server), not the web frontend (client).

---

## 📊 Options Summary Table

| Option | Module | Type | Default | Purpose |
|--------|--------|------|---------|---------|
| `enable` | server | bool | false | Start guacd |
| `enable` | client | bool | false | Start Tomcat |
| `host` | server | str | "127.0.0.1" | guacd binding |
| `port` | server | port | 4822 | guacd port |
| `userMappingXml` | **server** | path? | null | File auth ✅ |
| `settings` | **client** | attrs | {…} | Java config ✅ |
| `enableWebserver` | client | bool | true | Tomcat on/off |
| `logbackXml` | server | path? | null | Logging |
| `extraEnvironment` | server | attrs | {} | Env vars |
| `package` | server/client | package | v1.6.0 | Which version |

**Note**: `userMappingXml` only in `services.guacamole-server` ✅

---

## ⚠️ Common Mistakes

| Mistake | Why Wrong | Fix |
|---------|----------|-----|
| `guacamole-client.userMappingXml` | Option doesn't exist there | Move to `guacamole-server` |
| `settings.userMappingXml = ...` | Wrong type (settings is properties dict) | Use top-level `userMappingXml` option |
| Auth in both modules | Architectural mismatch | Choose: file (server) or DB (client) |
| Forgetting `enable = true` | Service won't start | Add enable option to both |
| Wrong hostname for guacd | Can't connect | Check `guacd-hostname` in settings |

---

## 🚀 Quick Start Examples

### Minimal Config

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
}
```

### With File Auth

```nix
{
  services.guacamole-server = {
    enable = true;
    userMappingXml = ./user-mapping.xml;
  };
  services.guacamole-client.enable = true;
}
```

### With Database

```nix
{
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
}
```

### With Reverse Proxy

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
  
  services.caddy.enable = true;
  services.caddy.virtualHosts."guac.example.com" = {
    extraConfig = ''
      reverse_proxy localhost:8080 {
        flush_interval -1
      }
    '';
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

## 🔗 Document Cross-References

### If you need to...

| Task | Read | Lines |
|------|------|-------|
| Get all options in one place | `CORRECT_NIXOS_OPTIONS.md` | "Correct NixOS Options" |
| Verify the error is real | `VERIFICATION_SUMMARY.md` | "Verification Results" |
| See the actual nixpkgs code | `NIXPKGS_SOURCE_CODE.md` | "File: guacamole-server.nix" |
| Quick reference table | `QUICK_OPTION_REFERENCE.md` | "Complete Option Reference" |
| Configure authentication | `CORRECT_NIXOS_OPTIONS.md` | "User Authentication Methods" |
| Fix network issues | `CORRECT_NIXOS_OPTIONS.md` | "Network Configuration" |
| Debug configuration | `CORRECT_NIXOS_OPTIONS.md` | "Proper Syntax Examples" |

---

## ✅ Verification Status

**Document Status**: ✅ VERIFIED  
**Last Updated**: November 17, 2025  
**Source**: nixpkgs master branch  

### Verification Method
- ✅ Live fetch of `guacamole-server.nix`
- ✅ Live fetch of `guacamole-client.nix`
- ✅ Live fetch of test configuration
- ✅ Manual source code review
- ✅ Cross-reference with existing research

### Confirmed Points
- ✅ `services.guacamole-server.userMappingXml` exists
- ✅ `services.guacamole-client.userMappingXml` does NOT exist
- ✅ Correct module distribution
- ✅ Type definitions
- ✅ Default values
- ✅ Generated file locations

---

## 📞 Next Steps

1. **Review your configuration**: Check if you're using `userMappingXml` in `guacamole-client`
2. **Move if needed**: Relocate to `guacamole-server`
3. **Validate**: Run `nix flake check`
4. **Build**: Run `nb` to build the configuration
5. **Apply**: Run `nup` when ready (after reviewing changes)

---

## 📝 Summary

Your finding is **100% correct and important**:

```
❌ WRONG:  services.guacamole-client.userMappingXml
✅ RIGHT:  services.guacamole-server.userMappingXml
```

This is not just a typo - it's an architectural difference. Authentication is handled by the backend server (`guacd`), not the web client (Tomcat). The correct separation of concerns is now documented and verified.

