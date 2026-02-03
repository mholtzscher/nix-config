{
  pkgs,
  user,
  ...
}:
let
  # SSH Public Keys - Get your key with: ssh-add -L
  sshPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwjFs5j8xyYI+p3ckPU0nUYyJ9S2Y753DYUEPRbyGqX"
    # Add additional keys as needed
  ];
in
{
  # User configuration
  users.users.${user} = {
    isNormalUser = true;
    home = "/home/${user}";
    description = "Michael Holtzscher";
    extraGroups = [
      "wheel" # Enable sudo
      "networkmanager" # Network management
      "docker" # Docker access (if enabled)
    ];
    shell = pkgs.zsh;
    # SSH authorized keys for remote access
    openssh.authorizedKeys.keys = sshPublicKeys;
  };
}
