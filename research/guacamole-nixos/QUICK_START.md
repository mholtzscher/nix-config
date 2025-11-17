# Guacamole on NixOS - Quick Start Guide

## Minimal Configuration

This is the simplest working Guacamole setup on NixOS:

```nix
# In hosts/nixos/your-host.nix or modules/nixos/hosts/your-host/default.nix

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
}
```

After rebuild:
- Access Guacamole at: `http://localhost:8080/guacamole`
- Default credentials: `guacadmin` / `guacadmin` (change immediately!)

## With User Mapping (Simple Authentication)

For basic file-based authentication without a database:

```nix
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
}
```

Create `user-mapping.xml` in the same directory:

```xml
<user-mapping>
  <authorize username="username1" password="password1">
    <connection name="rdp-example">
      <protocol>rdp</protocol>
      <param name="hostname">192.168.1.100</param>
      <param name="port">3389</param>
      <param name="username">admin</param>
      <param name="password">adminpass</param>
      <param name="ignore-cert">true</param>
    </connection>

    <connection name="ssh-example">
      <protocol>ssh</protocol>
      <param name="hostname">example.com</param>
      <param name="port">22</param>
      <param name="username">sshuser</param>
    </connection>
  </authorize>
</user-mapping>
```

## With Reverse Proxy (Caddy)

For accessing Guacamole via domain with HTTPS:

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;

  services.caddy = {
    enable = true;
    virtualHosts."guacamole.example.com" = {
      serverAddresses = [ "0.0.0.0:443" ];
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

## Validating Configuration

Before applying changes:

```bash
# Check Nix syntax
nix flake check

# Validate build without switching
darwin-rebuild build --flake .
# or
sudo nixos-rebuild build --flake .
```

## Accessing Guacamole

After configuration is applied:

1. **Local access**: `http://localhost:8080/guacamole`
2. **With reverse proxy**: `https://guacamole.example.com`
3. **From another host**: `http://<host-ip>:8080/guacamole`

## Default Credentials

Username: `guacadmin`
Password: `guacadmin`

**⚠️ IMPORTANT**: Change these immediately! See NIXOS_OPTIONS.md for how to configure database authentication.

## Troubleshooting

### Guacamole not accessible on :8080
- Check Tomcat is running: `systemctl status tomcat`
- Check guacd is running: `systemctl status guacamole-server`
- Check firewall: `sudo ufw status` or `sudo firewall-cmd --list-all`

### Cannot connect to backend services (RDP, SSH)
- Verify guacd is listening: `netstat -tlnp | grep 4822`
- Check user-mapping.xml syntax (must be valid XML)
- Verify backend service credentials in mapping file

### HTTPS issues with reverse proxy
- Run `sudo systemctl restart caddy`
- Check cert generation: `sudo journalctl -u caddy -n 50`
- Ensure port 443 is open: `sudo ufw allow 443`

## Next Steps

- **Production setup**: See DATABASE_SETUP.md for MySQL/PostgreSQL
- **Multiple connections**: Expand user-mapping.xml with more `<connection>` elements
- **High availability**: See PROXY_CONFIG.md for load balancing
- **Security**: Configure HTTPS, change default passwords, use strong credentials
