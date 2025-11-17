# Reverse Proxy Configuration for Guacamole on NixOS

## Overview

A reverse proxy is recommended for production Guacamole deployments because:

- **HTTPS/TLS**: Encrypt all traffic
- **URL path**: Serve at `/` instead of `/guacamole` path
- **Performance**: Compression, caching, SSL offloading
- **Security**: Hide Tomcat details, implement rate limiting
- **Load balancing**: Distribute traffic across instances

## Caddy Proxy (Recommended - Easiest)

Caddy is simpler than Nginx and auto-manages certificates.

### Basic Configuration

```nix
{
  services.guacamole-server.enable = true;
  services.guacamole-client.enable = true;

  services.caddy = {
    enable = true;
    email = "admin@example.com";  # For Let's Encrypt cert registration
    
    virtualHosts."guacamole.example.com" = {
      extraConfig = ''
        reverse_proxy localhost:8080 {
          flush_interval -1
        }
      '';
    };
  };

  # Allow HTTPS traffic
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

After building, Caddy will:
1. Request certificate from Let's Encrypt
2. Automatically renew before expiration
3. Serve at `https://guacamole.example.com`

### Advanced Caddy Configuration

```nix
{
  services.caddy = {
    enable = true;
    email = "admin@example.com";
    
    virtualHosts."guacamole.example.com" = {
      extraConfig = ''
        # Enable compression
        encode gzip
        
        # Security headers
        header X-Content-Type-Options "nosniff"
        header X-Frame-Options "SAMEORIGIN"
        header X-XSS-Protection "1; mode=block"
        header Referrer-Policy "strict-origin-when-cross-origin"
        
        # Rate limiting
        @limited {
          rate 100/h
        }
        respond @limited 429
        
        # Reverse proxy with timeout for long connections
        reverse_proxy localhost:8080 {
          flush_interval -1
          header_up Host {host}
          header_up X-Real-IP {remote}
          header_up X-Forwarded-For {remote}
          header_up X-Forwarded-Proto {scheme}
          timeout 3600s
          read_timeout 3600s
          write_timeout 3600s
        }
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];  # QUIC
}
```

### Caddy with Multiple Paths

```nix
{
  services.caddy = {
    enable = true;
    virtualHosts."example.com" = {
      extraConfig = ''
        # Guacamole at /guacamole
        handle /guacamole* {
          reverse_proxy localhost:8080 {
            flush_interval -1
          }
        }

        # Other services at other paths
        handle /jenkins* {
          reverse_proxy localhost:8080
        }

        handle /nextcloud* {
          reverse_proxy localhost:8090
        }

        # Redirect root to Guacamole
        handle / {
          redir /guacamole
        }
      '';
    };
  };
}
```

### Caddy with Self-Signed Certificates

```nix
{
  services.caddy = {
    enable = true;
    
    virtualHosts."guacamole.local" = {
      extraConfig = ''
        tls internal
        reverse_proxy localhost:8080 {
          flush_interval -1
        }
      '';
    };
  };
}
```

---

## Nginx Proxy

For more control or existing Nginx infrastructure.

### Basic Configuration

```nix
{
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
          proxy_send_timeout 600s;
          proxy_connect_timeout 75s;
          
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $server_name;
        '';
      };
    };
  };

  # Auto-manage Let's Encrypt certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

### Nginx with Compression & Caching

```nix
{
  services.nginx = {
    enable = true;
    
    commonHttpConfig = ''
      gzip on;
      gzip_types text/plain text/css text/javascript application/json;
      gzip_min_length 1000;
      
      # Cache for static assets
      proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=guacamole:10m max_size=1g inactive=60m;
    '';
    
    virtualHosts."guacamole.example.com" = {
      forceSSL = true;
      enableACME = true;
      
      locations."/" = {
        proxyPass = "http://localhost:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_request_buffering off;
          
          # Don't cache WebSocket connections
          proxy_cache_bypass $http_upgrade;
          proxy_no_cache $http_upgrade;
          
          # Long timeouts for interactive sessions
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          proxy_connect_timeout 75s;
          
          # Forward headers
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Host $host;
          
          # WebSocket upgrade headers
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
        '';
      };
      
      # Static assets can be cached
      locations."~* \.(jpg|jpeg|png|gif|ico|css|js)$" = {
        proxyPass = "http://localhost:8080";
        extraConfig = ''
          proxy_cache guacamole;
          proxy_cache_valid 200 30m;
          add_header X-Cache-Status $upstream_cache_status;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

### Nginx at Custom Path

```nix
{
  services.nginx = {
    enable = true;
    
    virtualHosts."example.com" = {
      locations."/guacamole/" = {
        proxyPass = "http://localhost:8080/guacamole/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_request_buffering off;
          proxy_read_timeout 600s;
        '';
      };
    };
  };
}
```

---

## Apache Proxy

For organizations using Apache HTTP Server.

```nix
{
  services.apache2 = {
    enable = true;
    
    mods = [
      "proxy"
      "proxy_http"
      "proxy_wstunnel"
      "rewrite"
      "ssl"
    ];
    
    virtualHosts."guacamole.example.com" = {
      forceSSL = true;
      enableACME = true;
      
      extraConfig = ''
        ProxyPreserveHost On
        
        ProxyPass / http://localhost:8080/ nocanon
        ProxyPassReverse / http://localhost:8080/
        
        # WebSocket support
        RewriteEngine On
        RewriteCond %{HTTP:Upgrade} websocket [NC]
        RewriteCond %{HTTP:Connection} upgrade [NC]
        RewriteRule ^/?(.*) "ws://localhost:8080/$1" [P,L]
        
        # Timeouts
        ProxyTimeout 3600
        ProxyReadTimeout 3600
      '';
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

## Header Configuration Best Practices

### Standard Headers

These headers should be forwarded to Guacamole:

```
X-Real-IP: $remote_addr           # Client's real IP
X-Forwarded-For: $proxy_add_x_forwarded_for  # Proxy chain
X-Forwarded-Proto: $scheme         # Original protocol (http/https)
X-Forwarded-Host: $host            # Original hostname
```

### Security Headers

Recommended security headers:

```
X-Content-Type-Options: nosniff           # Prevent MIME type sniffing
X-Frame-Options: SAMEORIGIN               # Prevent clickjacking
X-XSS-Protection: 1; mode=block           # Old XSS protection
Strict-Transport-Security: max-age=31536000  # HSTS (1 year)
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'
```

### WebSocket Headers

Required for WebSocket connections:

```
Upgrade: websocket
Connection: upgrade
```

---

## SSL/TLS Configuration

### Let's Encrypt (Automatic)

```nix
{
  services.caddy = {
    enable = true;
    email = "admin@example.com";
    # Certificates automatically managed
  };

  # Or with Nginx
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
    defaults.provider = "letsencrypt";
  };

  services.nginx = {
    enable = true;
    virtualHosts."guacamole.example.com" = {
      enableACME = true;
      forceSSL = true;
    };
  };
}
```

### Self-Signed Certificates (Development)

```nix
{
  security.acme.certs."guacamole.local" = {
    postNew = ''
      mkdir -p /var/lib/acme/
      cp /var/lib/acme/guacamole.local/key.pem /var/lib/acme/guacamole.local/key.pem
    '';
  };

  services.nginx = {
    enable = true;
    virtualHosts."guacamole.local" = {
      sslCertificate = "/var/lib/acme/guacamole.local/cert.pem";
      sslCertificateKey = "/var/lib/acme/guacamole.local/key.pem";
    };
  };
}
```

---

## Troubleshooting Reverse Proxy

### WebSocket Connection Fails

**Symptoms**: "Connection refused" in browser console

**Solutions**:
- Ensure `flush_interval -1` in Caddy or `proxy_buffering off` in Nginx
- Check WebSocket upgrade headers are forwarded
- Verify Tomcat is running and accessible

### Cookies Lost/Session Not Persisting

**Symptoms**: Logged out after each action

**Solution**:
- Add `proxy_cookie_path` directive in Nginx:
  ```
  proxy_cookie_path / "/";
  ```
- Or forward `Host` header correctly

### Infinite Redirects

**Symptoms**: Redirect loop to /guacamole/...

**Solutions**:
- Ensure `X-Forwarded-Proto` header is set to original protocol
- Don't redirect root to `/guacamole/` if proxy already at root

### Slow Performance

**Solutions**:
- Disable compression for already-compressed data:
  ```
  gzip_types text/plain text/css; # Not images/video
  ```
- Increase proxy timeouts for long-running sessions
- Enable caching for static assets only

### Certificate Renewal Fails

**Check logs**:
```bash
sudo journalctl -u caddy -n 50
# or
sudo journalctl -u nginx -n 50
```

**Common causes**:
- Port 80 not open for ACME validation
- DNS not resolving
- Rate limits hit on Let's Encrypt
