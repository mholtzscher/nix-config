{ inputs, ... }:
{
  # 1Password integration for NixOS and Darwin

  flake.modules.nixos._1password = {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "michael" ];
    };
  };

  flake.modules.darwin._1password = {
    # 1Password is managed via homebrew casks on macOS
  };

  flake.modules.homeManager._1password =
    { ... }:
    {
      programs._1password = {
        enable = true;
        settings = {
          accounts = [
            "michael.1password.com"
            "michaelholtzscher.1password.com"
          ];
        };
      };
    };
}
