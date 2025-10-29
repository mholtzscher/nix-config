{ ... }:
{
  # Shared user management configuration
  # This module provides common patterns but actual user setup happens in host files
  #
  # Usage in host files:
  #   let
  #     user = "username";
  #   in
  #   {
  #     users.users.${user} = {
  #       name = user;
  #       home = lib.mkDefault (
  #         if pkgs.stdenv.isDarwin then "/Users/${user}"
  #         else "/home/${user}"
  #       );
  #     };
  #   }

  # This file currently serves as documentation and placeholder
  # User definitions remain in host-specific files for flexibility
  # Future: Could extract common user attributes here if patterns emerge
}
