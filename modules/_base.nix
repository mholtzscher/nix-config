{
  lib,
  config,
  inputs,
  ...
}:
{
  # Dendritic pattern core options
  options.flake = {
    # Make flake.modules mergeable across multiple flake-parts modules.
    # Each feature module contributes one key under flake.modules.*
    modules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.raw);
      default = { };
      description = "Exported modules (merged from dendritic feature modules)";
    };

    # Factory functions for parameterized module creation
    factory = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
      description = "Factory functions for creating parameterized modules";
    };

    # Helper library functions
    lib = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
      description = "Helper library functions for host configuration";
    };
  };

  # Export standard flake module outputs from flake.modules.*
  # This eliminates the "unknown flake output 'modules'" warning
  config.flake = {
    # Standard home-manager module export
    homeManagerModules = config.flake.modules.homeManager or { };

    # Standard nix-darwin module export
    darwinModules = config.flake.modules.darwin or { };

    # Standard NixOS module export
    nixosModules = config.flake.modules.nixos or { };

    # Helper library for creating host configurations
    lib = {
      # Create a nix-darwin system configuration
      mkDarwin =
        {
          system ? "aarch64-darwin",
          user,
          hostModules ? [ ],
          hmModules ? [ ],
          isWork ? false,
          hostname,
        }:
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs user;
            self = inputs.self;
            inherit isWork;
            currentSystemName = hostname;
            currentSystemUser = user;
          };
          modules = [
            inputs.home-manager.darwinModules.home-manager
            inputs.nix-homebrew.darwinModules.nix-homebrew
          ]
          ++ hostModules
          ++ [
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs user;
                  self = inputs.self;
                  inherit isWork;
                  isDarwin = true;
                  isLinux = false;
                  currentSystemName = hostname;
                  currentSystemUser = user;
                };
                users.${user} = {
                  home = {
                    username = user;
                    homeDirectory = "/Users/${user}";
                    stateVersion = "24.11";
                  };
                  programs.home-manager.enable = true;
                  imports = hmModules;
                };
              };
            }
          ];
        };

      # Create a NixOS system configuration
      mkNixos =
        {
          system ? "x86_64-linux",
          user,
          hostModules ? [ ],
          hmModules ? [ ],
          isWork ? false,
          hostname,
        }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs user;
            self = inputs.self;
            inherit isWork;
            currentSystemName = hostname;
            currentSystemUser = user;
          };
          modules = [
            inputs.home-manager.nixosModules.home-manager
          ]
          ++ hostModules
          ++ [
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs user;
                  self = inputs.self;
                  inherit isWork;
                  isDarwin = false;
                  isLinux = true;
                  currentSystemName = hostname;
                  currentSystemUser = user;
                };
                users.${user} = {
                  home = {
                    username = user;
                    homeDirectory = "/home/${user}";
                    stateVersion = "24.11";
                  };
                  programs.home-manager.enable = true;
                  imports = hmModules;
                };
              };
            }
          ];
        };

      # Create a standalone home-manager configuration
      mkHomeManager =
        {
          system ? "x86_64-linux",
          user,
          hmModules ? [ ],
          isWork ? false,
          hostname,
        }:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs { inherit system; };
          extraSpecialArgs = {
            inherit inputs user;
            self = inputs.self;
            inherit isWork;
            isDarwin = false;
            isLinux = true;
            currentSystemName = hostname;
            currentSystemUser = user;
          };
          modules = hmModules ++ [
            {
              home = {
                username = user;
                homeDirectory = "/home/${user}";
                stateVersion = "24.11";
              };
              programs.home-manager.enable = true;
              targets.genericLinux.enable = true;
            }
          ];
        };
    };

    # Factory functions for common patterns
    factory = {
      # Create user modules for nixos, darwin, and homeManager
      user =
        username:
        {
          isAdmin ? false,
          shell ? "zsh",
          extraGroups ? [ ],
        }:
        {
          nixos."${username}" =
            { lib, pkgs, ... }:
            {
              users.users."${username}" = {
                isNormalUser = true;
                home = "/home/${username}";
                extraGroups = (lib.optionals isAdmin [ "wheel" ]) ++ extraGroups;
                shell = if shell == "zsh" then pkgs.zsh else pkgs.${shell};
              };
              programs.zsh.enable = lib.mkIf (shell == "zsh") true;
            };

          darwin."${username}" =
            { lib, pkgs, ... }:
            {
              users.users."${username}" = {
                home = "/Users/${username}";
                shell = if shell == "zsh" then pkgs.zsh else pkgs.${shell};
              };
              system.primaryUser = lib.mkIf isAdmin "${username}";
              programs.zsh.enable = lib.mkIf (shell == "zsh") true;
            };

          homeManager."${username}" = {
            home.username = "${username}";
          };
        };
    };
  };
}
