{ pkgs, ... }:

{
  # Apache Guacamole Configuration
  # Remote desktop gateway supporting RDP, VNC, SSH, and Telnet
  # Access via: http://localhost:8080/guacamole

  services.guacamole-server = {
    enable = true;
    # File-based authentication (good for testing)
    userMappingXml = pkgs.writeText "user-mapping.xml" ''
      <user-mapping>
        <!-- Example user with password -->
        <authorize username="guacadmin" password="guacadmin">
          <!-- Example SSH connection -->
          <connection name="SSH Server">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
          </connection>
          
          <!-- Example RDP connection (Windows) -->
          <connection name="Windows RDP">
            <protocol>rdp</protocol>
            <param name="hostname">192.168.1.100</param>
            <param name="port">3389</param>
            <param name="username">administrator</param>
          </connection>
          
          <!-- Example VNC connection -->
          <connection name="VNC Server">
            <protocol>vnc</protocol>
            <param name="hostname">localhost</param>
            <param name="port">5901</param>
          </connection>
        </authorize>
      </user-mapping>
    '';
  };

  services.guacamole-client = {
    enable = true;
    # Tomcat runs on port 8080 by default
    settings = {
      guacd-hostname = "localhost";
      guacd-port = 4822;
    };
  };

  # Open firewall ports for Guacamole
  networking.firewall.allowedTCPPorts = [
    4822 # guacd daemon port
    8080 # Tomcat web server port
  ];

  # Optional: Add PostgreSQL for production use
  # services.postgresql = {
  #   enable = true;
  #   ensureDatabases = [ "guacamole_db" ];
  #   ensureUsers = [
  #     {
  #       name = "guacamole_user";
  #       ensurePermissions = {
  #         "DATABASE guacamole_db" = "ALL PRIVILEGES";
  #       };
  #     }
  #   ];
  # };

  # Optional: Add Caddy reverse proxy for HTTPS
  # services.caddy = {
  #   enable = true;
  #   virtualHosts."guacamole.local".extraConfig = ''
  #     reverse_proxy localhost:8080
  #   '';
  # };
}
