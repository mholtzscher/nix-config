# Shared LSP servers and development tools
# Used by both Neovim and Helix configurations
{ pkgs }:
with pkgs;
[
  # Infrastructure
  terraform-ls
  dockerfile-language-server
  docker-compose-language-service
  yaml-language-server
  # marksman

  # Go
  gopls
  golangci-lint
  golangci-lint-langserver
  delve

  # Nix
  nil
  nixfmt

  # Protocol Buffers
  buf

  # Shell
  bash-language-server

  # Task runners
  just-lsp

  # Lua
  lua-language-server

  # Python
  ruff

  # Config formats
  kdlfmt # KDL
  taplo # TOML

  # TypeScript / JavaScript
  typescript-language-server
  prettier
  biome

  # VSCode language servers (CSS, HTML, JSON, ESLint, Markdown)
  vscode-langservers-extracted
]
