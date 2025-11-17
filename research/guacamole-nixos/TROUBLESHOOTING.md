# Guacamole on NixOS - Troubleshooting Guide

## Service Status & Logs

### Check if Services are Running

```bash
# Check guacamole-server (guacd)
systemctl status guacamole-server
systemctl is-active guacamole-server

# Check Tomcat (web server)
systemctl status tomcat
systemctl is-active tomcat

# Check reverse proxy (if enabled)
systemctl status caddy  # or nginx/apache2
```

### View Service Logs

```bash
# Last 50 lines of guacamole-server logs
journalctl -u guacamole-server -n 50

# Follow guacamole-server logs in real time
journalctl -u guacamole-server -f

# Follow Tomcat logs
journalctl -u tomcat -f

# Show errors only
journalctl -u guacamole-server -p err
```

### Check Network Connectivity

```bash
# Is guacd listening on 4822?
netstat -tlnp | grep 4822
ss -tlnp | grep 4822

# Is Tomcat listening on 8080?
netstat -tlnp | grep 8080

# Test connection from localhost
telnet localhost 4822
telnet localhost 8080
```

---

## Common Issues & Solutions

### Issue 1: "Connection Refused" - Cannot Access Guacamole

**Symptoms**:
- Browser shows `ERR_REFUSED_CONNECTION` or `Connection refused`
- Cannot reach `http://localhost:8080/guacamole`

**Diagnosis**:
```bash
# Check if Tomcat is running
systemctl status tomcat

# Check if port 8080 is listening
netstat -tlnp | grep 8080

# Check if firewall is blocking
sudo ufw status
sudo firewall-cmd --list-all
```

**Solutions**:

1. **Tomcat not running**:
   ```bash
   # Start Tomcat
   sudo systemctl start tomcat
   
   # Check for errors
   journalctl -u tomcat -n 100
   ```

2. **Port 8080 in use**:
   ```bash
   # Find process using port 8080
   sudo lsof -i :8080
   sudo ss -tlnp | grep 8080
   
   # Change Tomcat port in config
   # Edit: services.tomcat.port = 8081;
   ```

3. **Firewall blocking**:
   ```bash
   # UFW
   sudo ufw allow 8080
   
   # Firewalld
   sudo firewall-cmd --add-port=8080/tcp --permanent
   sudo firewall-cmd --reload
   ```

4. **Rebuild didn't apply**:
   ```bash
   # Apply changes
   sudo nixos-rebuild switch
   ```

---

### Issue 2: Guacamole Web UI Loads but Cannot Connect to Backend

**Symptoms**:
- Login works (or no login)
- Click connection → "Connection Failed"
- Error in browser: "Connection terminated"

**Diagnosis**:
```bash
# Is guacd running?
systemctl status guacamole-server
netstat -tlnp | grep 4822

# Can Tomcat reach guacd?
telnet localhost 4822

# Check guacd logs
journalctl -u guacamole-server -n 50
```

**Solutions**:

1. **guacd not running**:
   ```bash
   sudo systemctl start guacamole-server
   ```

2. **guacd listening on wrong host**:
   ```nix
   # Check configuration
   services.guacamole-server.host = "127.0.0.1";  # Wrong for remote connections
   
   # Fix: Change to
   services.guacamole-server.host = "0.0.0.0";
   ```

3. **Connection parameters wrong**:
   - Check `user-mapping.xml` for correct hostnames and ports
   - Verify backend services are actually running
   - Test direct connection to backend (RDP, VNC, SSH)

4. **guacd connection settings**:
   ```nix
   # Ensure client knows where guacd is
   services.guacamole-client.settings = {
     guacd-hostname = "localhost";  # or actual hostname
     guacd-port = 4822;
   };
   ```

---

### Issue 3: "404 Not Found" - Guacamole Path Wrong

**Symptoms**:
- Navigate to `localhost:8080` shows Tomcat page
- `/guacamole` path shows 404

**Diagnosis**:
```bash
# Check Tomcat webapps
ls -la /run/tomcat/webapps/

# Verify guacamole.war is deployed
test -f /run/tomcat/webapps/guacamole.war && echo "Found" || echo "Missing"
```

**Solutions**:

1. **guacamole-client not enabled**:
   ```nix
   services.guacamole-client.enable = true;
   ```

2. **Rebuild required**:
   ```bash
   sudo nixos-rebuild switch
   ```

3. **Tomcat not deployed correctly**:
   ```bash
   # Check systemd service
   systemctl status tomcat
   
   # Restart
   sudo systemctl restart tomcat
   
   # Wait for deployment (usually 10-20 seconds)
   sleep 15
   
   # Check again
   ls -la /run/tomcat/webapps/
   ```

---

### Issue 4: Authentication Fails - Blank Screen or Wrong Password

**Symptoms**:
- Login page appears
- Enter credentials → "Authentication failed" or error
- Credentials definitely correct

**Diagnosis**:
```bash
# Check user-mapping.xml exists
cat /etc/guacamole/user-mapping.xml

# Check syntax validity
xmllint /etc/guacamole/user-mapping.xml

# Check guacamole.properties
cat /etc/guacamole/guacamole.properties
```

**Solutions**:

1. **user-mapping.xml has XML errors**:
   ```bash
   xmllint /etc/guacamole/user-mapping.xml
   # Fix XML syntax
   # Rebuild
   sudo nixos-rebuild switch
   ```

2. **User not in mapping file**:
   - Check username and password in `user-mapping.xml`
   - Remember: XML is case-sensitive
   - Add user entry if missing

3. **Password mismatch**:
   - Passwords in user-mapping.xml are plain text
   - Verify exact match (including case)

4. **Default credentials not changed**:
   ```bash
   # If using database, change via web UI
   # If using XML:
   # Edit user-mapping.xml:
   <authorize username="admin" password="new-secure-password">
   
   # Rebuild
   sudo nixos-rebuild switch
   ```

---

### Issue 5: WebSocket Connection Failed (Reverse Proxy)

**Symptoms**:
- Works on `localhost:8080` directly
- Via reverse proxy at `guacamole.example.com`: WebSocket errors
- Browser console: "WebSocket connection closed"

**Diagnosis**:
```bash
# Check reverse proxy config
systemctl status caddy
journalctl -u caddy -n 50

# Verify proxy is forwarding correctly
# Test from client machine:
curl -i https://guacamole.example.com/
```

**Solutions**:

1. **Caddy/Nginx not forwarding WebSocket headers**:
   ```nix
   # Caddy fix:
   services.caddy.virtualHosts."..." = {
     extraConfig = ''
       reverse_proxy localhost:8080 {
         flush_interval -1  # ← CRITICAL for WebSocket
       }
     '';
   };
   
   # Nginx fix:
   services.nginx.virtualHosts."..." = {
     locations."/" = {
       extraConfig = ''
         proxy_buffering off;
         proxy_request_buffering off;
       '';
     };
   };
   ```

2. **Missing flush_interval or buffering disabled**:
   - Rebuild and restart proxy

3. **SSL/TLS issues**:
   ```bash
   # Check certificate
   openssl x509 -in /path/to/cert.pem -text -noout
   
   # Check cert renewal
   journalctl -u caddy | grep -i cert
   ```

---

### Issue 6: Connection Hangs or Closes After N Seconds

**Symptoms**:
- Connect successfully → desktop appears
- After 5 minutes (or specific time) → disconnected
- No error message

**Diagnosis**:
- Likely timeout configuration
- Check guacamole.properties settings

**Solutions**:

1. **Increase user timeout**:
   ```nix
   services.guacamole-client.settings = {
     user-timeout = "600000";  # 10 minutes in ms
   };
   ```

2. **Increase session timeout**:
   ```nix
   services.guacamole-client.settings = {
     session-timeout = "3600000";  # 1 hour in ms
   };
   ```

3. **Check reverse proxy timeouts**:
   ```nix
   # Caddy
   services.caddy.virtualHosts."..." = {
     extraConfig = ''
       reverse_proxy localhost:8080 {
         flush_interval -1
         timeout 3600s
       }
     '';
   };
   
   # Nginx
   locations."/" = {
     extraConfig = ''
       proxy_read_timeout 600s;
       proxy_send_timeout 600s;
     '';
   };
   ```

---

### Issue 7: RDP Connection Fails

**Symptoms**:
- Select RDP connection → Error "Failed to connect"
- guacd logs show protocol error

**Diagnosis**:
```bash
# Check if RDP server is accessible
telnet <rdp-host> 3389

# Check if credentials in user-mapping.xml are correct
cat /etc/guacamole/user-mapping.xml | grep -A 10 "protocol>rdp"

# Check guacd logs for details
journalctl -u guacamole-server -n 100 | grep -i rdp
```

**Solutions**:

1. **RDP server unreachable**:
   - Verify IP/hostname is correct
   - Check network connectivity: `ping <rdp-host>`
   - Check firewall on RDP server
   - Check port 3389 is open

2. **Wrong credentials**:
   - Verify username/password in user-mapping.xml
   - Test credentials directly on RDP server

3. **RDP certificate issues**:
   ```nix
   # In user-mapping.xml, allow self-signed:
   <param name="ignore-cert">true</param>
   ```

4. **TLS/NLA requirements**:
   - If RDP requires NLA (Network Level Authentication):
     ```xml
     <param name="security">any</param>
     <param name="disable-auth">true</param>
     ```

---

### Issue 8: SSH Connection Issues

**Symptoms**:
- SSH connection fails or hangs
- "Authentication failed" or "Connection refused"

**Diagnosis**:
```bash
# Test SSH connection directly
ssh -v user@host

# Check SSH key permissions in user-mapping.xml
cat /etc/guacamole/user-mapping.xml | grep -A 10 "protocol>ssh"
```

**Solutions**:

1. **SSH server not accessible**:
   ```bash
   telnet <ssh-host> 22
   ```

2. **SSH key file not found**:
   - Keys in user-mapping.xml should be absolute paths
   - Verify file exists and is readable

3. **SSH authentication method mismatch**:
   ```xml
   <!-- Try password instead of key -->
   <connection name="SSH">
     <protocol>ssh</protocol>
     <param name="hostname">ssh.example.com</param>
     <param name="username">user</param>
     <param name="password">pass</param>
   </connection>
   ```

---

### Issue 9: Database Connection Failed

**Symptoms**:
- Guacamole shows "Authentication failed"
- PostgreSQL/MySQL settings configured
- Error: "could not connect to server"

**Diagnosis**:
```bash
# Check if database is running
systemctl status postgresql
systemctl status mysql

# Test connection manually
psql -U guacamole -d guacamole -h localhost
mysql -u guacamole -p guacamole

# Check guacamole.properties
cat /etc/guacamole/guacamole.properties | grep -i postgresql
```

**Solutions**:

1. **Database server not running**:
   ```bash
   sudo systemctl start postgresql  # or mysql
   ```

2. **Wrong connection settings**:
   ```nix
   # Check hostname, port, database name, username
   services.guacamole-client.settings = {
     postgresql-hostname = "localhost";
     postgresql-port = 5432;  # 3306 for MySQL
     postgresql-database = "guacamole";
     postgresql-username = "guacamole";
   };
   ```

3. **Schema not initialized**:
   ```bash
   # Check if tables exist
   psql -U guacamole -d guacamole -c "\dt"
   
   # If empty, run schema initialization
   # See DATABASE_SETUP.md
   ```

4. **Credentials wrong**:
   ```bash
   # Test manually
   psql -U guacamole -d guacamole -h localhost
   # Enter password when prompted
   ```

---

## Getting Help

### Collect Diagnostic Information

Before asking for help, collect:

```bash
# Configuration
cat /etc/guacamole/guacamole.properties
cat /etc/guacamole/user-mapping.xml 2>/dev/null || echo "No user-mapping.xml"

# Service status
systemctl status guacamole-server tomcat

# Recent logs (last 100 lines)
journalctl -u guacamole-server -n 100 > guacamole-server.log
journalctl -u tomcat -n 100 > tomcat.log

# Network info
netstat -tlnp | grep -E "(4822|8080)" > network.log

# System info
uname -a > system-info.log
nix --version >> system-info.log
```

### Useful Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/
- **Guacamole Docs**: https://guacamole.apache.org/doc/
- **NixOS Discourse**: https://discourse.nixos.org/
- **GitHub Issues**: https://github.com/NixOS/nixpkgs/issues

### Enable Debug Logging

```nix
{
  services.guacamole-server = {
    extraEnvironment = {
      DEBUG_LEVEL = "TRACE";  # More verbose logging
    };
  };

  services.guacamole-client.settings = {
    "log4j.rootCategory" = "DEBUG";
  };
}
```

---

## Performance Issues

### Slow Connection Speed

**Solutions**:
```nix
{
  # Increase Java heap
  services.tomcat.jvmOpts = [ "-Xms1g" "-Xmx2g" ];
  
  # Enable compression in proxy
  services.caddy.virtualHosts."..." = {
    extraConfig = ''encode gzip'';
  };
  
  # Tune display settings
  services.guacamole-client.settings = {
    "enable-display-cache" = "true";
  };
}
```

### High Memory Usage

**Solutions**:
- Reduce Java heap: `-Xmx512m`
- Limit concurrent sessions
- Use database for stateless scaling

### CPU High

**Diagnosis**:
```bash
top
htop
perf top  # Advanced
```

**Solutions**:
- Check for runaway processes
- Review connection parameters for inefficient settings
- Consider horizontal scaling
