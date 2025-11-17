# Actual nixpkgs Source Code (Verified)

This document contains the actual source code from nixpkgs that defines the Guacamole options.

---

## File: `nixos/modules/services/web-apps/guacamole-server.nix`

**Location**: https://raw.githubusercontent.com/NixOS/nixpkgs/master/nixos/modules/services/web-apps/guacamole-server.nix

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.guacamole-server;
in
{
  options = {
    services.guacamole-server = {
      enable = lib.mkEnableOption "Apache Guacamole Server (guacd)";
      package = lib.mkPackageOption pkgs "guacamole-server" { };

      extraEnvironment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = lib.literalExpression ''
          {
            ENVIRONMENT = "production";
          }
        '';
        description = "Environment variables to pass to guacd.";
      };

      host = lib.mkOption {
        default = "127.0.0.1";
        description = ''
          The host name or IP address the server should listen to.
        '';
        type = lib.types.str;
      };

      port = lib.mkOption {
        default = 4822;
        description = ''
          The port the guacd server should listen to.
        '';
        type = lib.types.port;
      };

      logbackXml = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/path/to/logback.xml";
        description = ''
          Configuration file that correspond to `logback.xml`.
        '';
      };

      userMappingXml = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/path/to/user-mapping.xml";
        description = ''
          Configuration file that correspond to `user-mapping.xml`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Setup configuration files.
    environment.etc."guacamole/logback.xml" = lib.mkIf (cfg.logbackXml != null) {
      source = cfg.logbackXml;
    };
    environment.etc."guacamole/user-mapping.xml" = lib.mkIf (cfg.userMappingXml != null) {
      source = cfg.userMappingXml;
    };

    systemd.services.guacamole-server = {
      description = "Apache Guacamole server (guacd)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        HOME = "/run/guacamole-server";
      }
      // cfg.extraEnvironment;
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -f -b ${cfg.host} -l ${toString cfg.port}";
        RuntimeDirectory = "guacamole-server";
        DynamicUser = true;
        PrivateTmp = "yes";
        Restart = "on-failure";
      };
    };
  };
}
```

**Key observations**:
1. `userMappingXml` is defined as `lib.types.nullOr lib.types.path` (optional path)
2. Location: `services.guacamole-server`
3. When set, it's copied to `/etc/guacamole/user-mapping.xml`
4. Service runs with `DynamicUser = true` (unprivileged user)
5. Auto-restarts on failure

---

## File: `nixos/modules/services/web-apps/guacamole-client.nix`

**Location**: https://raw.githubusercontent.com/NixOS/nixpkgs/master/nixos/modules/services/web-apps/guacamole-client.nix

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.guacamole-client;
  settingsFormat = pkgs.formats.javaProperties { };
in
{
  options = {
    services.guacamole-client = {
      enable = lib.mkEnableOption "Apache Guacamole Client (Tomcat)";
      package = lib.mkPackageOption pkgs "guacamole-client" { };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = settingsFormat.type;
        };
        default = {
          guacd-hostname = "localhost";
          guacd-port = 4822;
        };
        description = ''
          Configuration written to `guacamole.properties`.

          ::: {.note}
          The Guacamole web application uses one main configuration file called
          `guacamole.properties`. This file is the common location for all
          configuration properties read by Guacamole or any extension of
          Guacamole, including authentication providers.
          :::
        '';
      };

      enableWebserver = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable the Guacamole web application in a Tomcat webserver.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."guacamole/guacamole.properties" = lib.mkIf (cfg.settings != { }) {
      source = (settingsFormat.generate "guacamole.properties" cfg.settings);
    };

    services = lib.mkIf cfg.enableWebserver {
      tomcat = {
        enable = true;
        webapps = [
          cfg.package
        ];
      };
    };
  };
}
```

**Key observations**:
1. ⚠️ **NO `userMappingXml` option exists here!** This is the user's error
2. Settings are written as Java properties format
3. Only has `enable`, `package`, `settings`, and `enableWebserver`
4. Auto-enables `services.tomcat` when enabled
5. `settings` uses `freeformType` - accepts any Java property key

---

## File: `nixos/tests/guacamole-server.nix`

**Location**: https://raw.githubusercontent.com/NixOS/nixpkgs/master/nixos/tests/guacamole-server.nix

```nix
{ pkgs, lib, ... }:
{
  name = "guacamole-server";

  nodes = {
    machine =
      { pkgs, ... }:
      {
        services.guacamole-server = {
          enable = true;
          host = "0.0.0.0";
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("guacamole-server.service")
    machine.wait_for_open_port(4822)
  '';

  meta.maintainers = [ ];
}
```

**Key observations**:
1. Basic test configuration
2. Only enables `guacamole-server`, not client
3. Listens on all interfaces (`0.0.0.0`)
4. Verifies service starts and port opens

---

## Package Files

### `pkgs/by-name/gu/guacamole-server/package.nix`

Typically includes:
- Version (1.6.0)
- Build dependencies
- Compilation flags
- Installation paths

### `pkgs/by-name/gu/guacamole-client/package.nix`

Typically includes:
- Version (1.6.0)
- WAR file generation
- Tomcat integration
- Installation paths

---

## What These Tell Us

### ✅ Confirmed Correct

```nix
# This WORKS
services.guacamole-server = {
  enable = true;
  host = "127.0.0.1";
  port = 4822;
  userMappingXml = ./user-mapping.xml;  # ✅ CORRECT - in server module
};

services.guacamole-client = {
  enable = true;
  settings = {
    guacd-hostname = "localhost";
    guacd-port = 4822;
  };
};
```

### ❌ Confirmed Wrong

```nix
# This DOES NOT WORK
services.guacamole-client = {
  enable = true;
  userMappingXml = ./user-mapping.xml;  # ❌ WRONG - option doesn't exist
};
```

---

## Type System

### `services.guacamole-server.userMappingXml`

```nix
# Type definition
type = lib.types.nullOr lib.types.path;

# What this means:
# - Value must be either: null (not set) or a valid path
# - Path is resolved by Nix (can be inline or reference)
# - Examples:
userMappingXml = ./local/file.xml;        # Relative path in flake
userMappingXml = /etc/guacamole/user.xml; # Absolute path
userMappingXml = pkgs.writeText "user-mapping.xml" ''...'';  # Generated file
userMappingXml = null;                    # Explicitly unset (default)
```

### `services.guacamole-client.settings`

```nix
# Type definition
type = lib.types.submodule {
  freeformType = settingsFormat.type;
};
# where settingsFormat = pkgs.formats.javaProperties { }

# What this means:
# - Can be any set of key-value pairs
# - Keys and values are strings
# - Written as Java properties format
# - Examples:
settings = {
  "key1" = "value1";
  "key2" = "value2";
};
```

---

## Configuration Files Generated

### From `services.guacamole-server`:

**Input**: `userMappingXml = ./user-mapping.xml`
**Output**: `/etc/guacamole/user-mapping.xml` (copied from input)

**Input**: `logbackXml = ./logback.xml`  
**Output**: `/etc/guacamole/logback.xml` (copied from input)

### From `services.guacamole-client.settings`:

**Input**:
```nix
settings = {
  guacd-hostname = "localhost";
  guacd-port = 4822;
};
```

**Output**: `/etc/guacamole/guacamole.properties`
```properties
guacd-hostname=localhost
guacd-port=4822
```

---

## Summary of Source Code Review

| Aspect | Server Module | Client Module | Conclusion |
|--------|---------------|---------------|-----------|
| `userMappingXml` | ✅ Exists | ❌ Does NOT exist | Use in SERVER only |
| `settings` | ❌ Does NOT exist | ✅ Exists | Use in CLIENT only |
| Auth mechanism | File-based XML | Database-based | Separate concerns |
| Responsibilities | Backend auth | Web config | Proper separation |

