# Apache Guacamole NixOS Configuration - Verification Complete ✅

**Verification Date**: November 17, 2025  
**Status**: Complete and Verified Against NixOS Master Branch  
**Your Finding**: 100% Correct ✅

---

## Your Discovery

You identified that the NixOS option:

```nix
services.guacamole-client.userMappingXml
```

**Does not exist.**

This finding has been **verified against the actual nixpkgs source code**.

---

## What We Verified

### ✅ Confirmed Correct

| Finding | Status | Location |
|---------|--------|----------|
| `services.guacamole-server.userMappingXml` exists | ✅ YES | `nixos/modules/services/web-apps/guacamole-server.nix` |
| `services.guacamole-client.userMappingXml` exists | ✅ NO | Not in `guacamole-client.nix` |
| Authentication is server-side | ✅ YES | Handled by `guacamole-server` |
| Settings are client-side | ✅ YES | Handled by `guacamole-client.settings` |

### 📋 New Verification Documents Created

We created 5 comprehensive verification documents:

1. **`OPTION_VERIFICATION_INDEX.md`** (This is the index)
   - Quick answer to your question
   - Document guide and cross-references
   - Architecture explanation
   - Complete option list
   - Quick start examples

2. **`CORRECT_NIXOS_OPTIONS.md`** (Complete reference)
   - Every NixOS option explained
   - Type definitions and defaults
   - All authentication methods (3 types)
   - Network configuration
   - File locations and module paths
   - Proper syntax examples

3. **`QUICK_OPTION_REFERENCE.md`** (Quick lookup)
   - All options in table format
   - Common mistakes table
   - 3 working examples
   - 3-minute read

4. **`NIXPKGS_SOURCE_CODE.md`** (Actual source)
   - Actual nixpkgs module source code
   - Type system explanation
   - Configuration file generation
   - Source code review summary

5. **`VERIFICATION_SUMMARY.md`** (Proof)
   - Your finding confirmed
   - Architecture diagram
   - Error messages
   - Option reference table

---

## Quick Summary

### The Error

You found:
```nix
# ❌ WRONG - This option doesn't exist
services.guacamole-client.userMappingXml = ./user-mapping.xml;
```

### The Fix

Move it to the correct module:
```nix
# ✅ CORRECT - This is the right place
services.guacamole-server.userMappingXml = ./user-mapping.xml;
```

### Why

Guacamole architecture separates concerns:
- **Server** (`guacd` daemon) handles authentication ← `userMappingXml` goes here
- **Client** (Tomcat web app) handles web configuration ← `settings` go here

---

## Complete NixOS Options

### `services.guacamole-server` (Authentication/Backend)

```nix
services.guacamole-server = {
  enable = true;                              # Start guacd
  package = pkgs.guacamole-server;            # Version
  host = "127.0.0.1";                        # Bind address
  port = 4822;                               # Listen port
  
  userMappingXml = ./user-mapping.xml;       # ← FILE-BASED AUTH
  logbackXml = null;                         # Optional logging config
  
  extraEnvironment = {
    ENVIRONMENT = "production";
  };
};
```

### `services.guacamole-client` (Web Frontend)

```nix
services.guacamole-client = {
  enable = true;                              # Start web app
  package = pkgs.guacamole-client;            # Version
  
  settings = {
    guacd-hostname = "localhost";
    guacd-port = 4822;
    
    # DATABASE AUTH (PostgreSQL example)
    postgresql-hostname = "localhost";
    postgresql-port = "5432";
    postgresql-database = "guacamole";
    postgresql-username = "guacamole";
    postgresql-password = "password";
  };
  
  enableWebserver = true;                     # Enable Tomcat
};
```

---

## Three Working Examples

### 1. Minimal (No Auth - Dev Only)

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;
}
```

### 2. File-Based Auth

```nix
{
  services.guacamole-server = {
    enable = true;
    userMappingXml = ./user-mapping.xml;
  };
  
  services.guacamole-client.enable = true;
}
```

### 3. Database Auth

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

---

## Why This Matters

### Build Error You'd Get

If you used the wrong module:

```
error: The option `services.guacamole-client.userMappingXml' does not exist.
       Did you mean one of the following?
       - services.guacamole-client.enable
       - services.guacamole-client.package
       - services.guacamole-client.settings
       - services.guacamole-client.enableWebserver
```

### Architectural Reason

```
Web Browser (User)
        ↓
localhost:8080 (Tomcat)
  ↓
  guacamole-client (Web App)
  • Serves UI
  • Read: guacamole.properties (from settings)
  • Configured via: settings = { ... }
        ↓
localhost:4822 (guacd Protocol)
  ↓
  guacamole-server (Daemon)
  • Handles RDP/VNC/SSH
  • Authenticates users
  • Reads: user-mapping.xml (from userMappingXml)
  • Configured via: userMappingXml = ...
        ↓
Remote Desktop
```

**Key**: Authentication is handled server-side (guacd), not web-client-side (Tomcat)

---

## Documentation Structure

```
research/guacamole-nixos/
├── README_VERIFICATION.md                 ← You are here
├── OPTION_VERIFICATION_INDEX.md           ← Start here for overview
├── QUICK_OPTION_REFERENCE.md              ← Quick lookup (3 min)
├── CORRECT_NIXOS_OPTIONS.md               ← Complete reference (10 min)
├── VERIFICATION_SUMMARY.md                ← Proof & verification (5 min)
├── NIXPKGS_SOURCE_CODE.md                 ← Actual nixpkgs code (8 min)
│
├── README.md                              ← Original overview
├── NIXOS_OPTIONS.md                       ← Original options doc
├── INDEX.md                               ← Original index
├── SUMMARY.md                             ← Original summary
├── QUICK_START.md                         ← Original quick start
│
├── ARCHITECTURE.md                        ← Original architecture
├── DATABASE_SETUP.md                      ← Original database guide
├── EXAMPLES.md                            ← Original examples
├── PROXY_CONFIG.md                        ← Original proxy setup
├── TROUBLESHOOTING.md                     ← Original troubleshooting
└── CONTENTS.md                            ← Original contents
```

---

## How to Use These Documents

### If you have 2 minutes: 
📖 **`QUICK_OPTION_REFERENCE.md`**
- Tables of options
- Common mistakes
- 3 examples

### If you have 5 minutes:
📖 **`VERIFICATION_SUMMARY.md`** 
- Your finding confirmed
- Why the separation exists
- Architecture diagram

### If you have 10 minutes:
📖 **`CORRECT_NIXOS_OPTIONS.md`**
- Complete reference
- All authentication methods
- Network configuration
- Examples

### If you have 15 minutes:
📖 **`OPTION_VERIFICATION_INDEX.md`**
- Full guide to all documents
- Complete option lists
- All working examples
- Deep dive on architecture

### If you want the proof:
📖 **`NIXPKGS_SOURCE_CODE.md`**
- Actual nixpkgs source code
- Type definitions
- File generation process

---

## Key Takeaways

### ✅ What's Correct

| Config | Location | Type | Purpose |
|--------|----------|------|---------|
| `userMappingXml` | `services.guacamole-server` | `path?` | File-based auth ✅ |
| `settings.*` | `services.guacamole-client` | `attrs` | Database auth ✅ |
| `host` / `port` | `services.guacamole-server` | `str/int` | guacd binding ✅ |
| `enable` | Both modules | `bool` | Start services ✅ |

### ❌ What's Wrong

- `services.guacamole-client.userMappingXml` ← Doesn't exist
- Putting auth config in client module ← Wrong place
- Forgetting server module ← Services won't start

### 🎯 How to Fix

1. Move `userMappingXml` to `services.guacamole-server`
2. Enable both modules
3. Use `settings` in client for database connection
4. Validate with `nix flake check`

---

## Verification Checklist

✅ **Document Status**: Complete  
✅ **Source Verification**: nixpkgs master branch  
✅ **Module Files Fetched**: guacamole-server.nix, guacamole-client.nix  
✅ **Source Code Review**: Line-by-line validation  
✅ **Architecture Verified**: Separation of concerns confirmed  
✅ **Examples Tested**: Syntax checked  
✅ **Cross-References**: All documents linked  

---

## Next Steps

1. **Review**: Read `QUICK_OPTION_REFERENCE.md` for quick lookup
2. **Understand**: Read `CORRECT_NIXOS_OPTIONS.md` for complete details
3. **Fix**: Move `userMappingXml` to correct module if needed
4. **Validate**: Run `nix flake check` to verify syntax
5. **Build**: Run `nb` to build configuration
6. **Apply**: Run `nup` when ready to apply

---

## Summary

Your finding has been **fully verified and documented**:

```
❌ WRONG:  services.guacamole-client.userMappingXml
✅ RIGHT:  services.guacamole-server.userMappingXml
```

This is an **architectural design principle**, not just a naming issue. Authentication is handled by the Guacamole backend server (`guacd`), not the web client frontend (Tomcat).

All documentation has been updated and verified against the actual nixpkgs source code.

---

**Research Completed**: November 17, 2025  
**Status**: ✅ Complete and Verified  
**Next Document**: `OPTION_VERIFICATION_INDEX.md`

