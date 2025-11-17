# Apache Guacamole on NixOS - Comprehensive Research

This research directory contains comprehensive documentation for configuring Apache Guacamole on NixOS.

## Contents

1. **QUICK_START.md** - Get started quickly with basic Guacamole setup
2. **NIXOS_OPTIONS.md** - Complete reference of NixOS Guacamole configuration options
3. **ARCHITECTURE.md** - System components and how they work together
4. **DATABASE_SETUP.md** - Database configuration for production deployments
5. **PROXY_CONFIG.md** - Reverse proxy setup with Caddy/Nginx
6. **EXAMPLES.md** - Real-world configuration examples
7. **TROUBLESHOOTING.md** - Common issues and solutions

## Overview

Apache Guacamole is a clientless remote desktop gateway that supports VNC, RDP, SSH, and Telnet connections through a web browser.

In NixOS, Guacamole consists of two main services:

- **guacamole-server (guacd)**: The backend daemon handling protocol connections
- **guacamole-client**: The web application (runs on Tomcat)

## Key Findings

### Available NixOS Modules

- `services.guacamole-server` - Guacd daemon configuration
- `services.guacamole-client` - Web client and Tomcat integration
- `services.tomcat` - Web application server (auto-enabled by client)

### Default Ports

- **guacd**: 4822 (internal communication)
- **Tomcat**: 8080 (web interface)
- **HTTP**: 80 (reverse proxy)
- **HTTPS**: 443 (reverse proxy)

### Supported Authentication Methods

- User mapping XML (simple file-based)
- JDBC database (MySQL, PostgreSQL)
- OIDC/OAuth (via extensions)
- LDAP (via extensions)

## Quick Links

- [NixOS Guacamole Modules](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/services/web-apps)
- [Apache Guacamole Documentation](https://guacamole.apache.org/doc/)
- [Guacamole Properties Reference](https://guacamole.apache.org/doc/gug/configuring-guacamole.html)

## Research Sources

- NixOS nixpkgs modules: `nixos/modules/services/web-apps/guacamole-*.nix`
- NixOS tests: `nixos/tests/guacamole-server.nix`
- Community implementations: drupol/infra, Tarow/nix-podman-stacks
