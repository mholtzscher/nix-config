# Coding standards

- When adding a Neovim plugin, use `vim.pack` and configure it in `init.lua`.
- Before implementing OS-specific or machine-specific behavior or changing platform guards/module arguments, read `docs/platform-guidelines.md`. It defines platform checks, host isolation, and module argument patterns.
