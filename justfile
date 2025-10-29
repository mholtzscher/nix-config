# Common Nix configuration commands
# Run `just` or `just --list` to see all available commands

# Default recipe
default:
    @just --list

# Validate all configurations without applying them
validate:
    @echo "Validating all Nix configurations..."
    @echo ""
    @echo "Checking flake syntax..."
    nix flake check
    @echo ""
    @echo "Building personal-mac configuration..."
    darwin-rebuild build --flake .#Michaels-M1-Max
    @echo ""
    @echo "Building work-mac configuration..."
    darwin-rebuild build --flake .#Michael-Holtzscher-Work
    @echo ""
    @echo "Building desktop configuration..."
    nix build .#nixosConfigurations.desktop.config.system.build.toplevel
    @echo ""
    @echo "✓ All configurations are valid!"

# Validate personal Mac configuration
validate-personal:
    @echo "Validating personal-mac configuration..."
    darwin-rebuild build --flake .#Michaels-M1-Max

# Validate work Mac configuration
validate-work:
    @echo "Validating work-mac configuration..."
    darwin-rebuild build --flake .#Michael-Holtzscher-Work

# Validate NixOS desktop configuration
validate-desktop:
    @echo "Validating desktop configuration..."
    nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Check flake inputs and show updates available
check-updates:
    @echo "Checking for flake input updates..."
    nix flake update --dry-run

# Update all flake inputs
update-inputs:
    @echo "Updating flake inputs..."
    nix flake update

# # Show what would change in current generation
# diff-build personal:
#     darwin-rebuild build-dry --flake .#Michaels-M1-Max
#
# diff-build work:
#     darwin-rebuild build-dry --flake .#Michael-Holtzscher-Work
#
# diff-build desktop:
#     darwin-rebuild build-dry --flake .#desktop

# List all available recipes
help:
    @just --list

# Garbage collect (requires confirmation)
gc:
    @echo "Garbage collecting Nix store..."
    nix store gc --verbose
    @echo "✓ Garbage collection complete!"

# Show Nix store statistics
store-stats:
    @echo "Nix store statistics:"
    du -sh ~/.nix-profile
    du -sh /nix/store

# View flake metadata
flake-info:
    nix flake metadata

# Lint: check for common issues (basic)
lint:
    @echo "Running basic linting checks..."
    nix flake check
    @echo "✓ Linting complete!"
