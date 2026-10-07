# AGENTS.md

## Safety

- Never apply Nix changes. This includes `nh darwin switch`, `nh os switch`, `nh home switch`, `darwin-rebuild switch`, `nixos-rebuild switch`, `home-manager switch`, `nup`, and any other apply command. Only the user runs these, outside the agent.
- Run `nix flake update` only when the user explicitly requests it.
- Never handle plaintext secrets or place secret values inline in Nix. The user enters real values through `./scripts/secrets edit`.
- Use `./scripts/secrets` for all secret work, never `agenix` directly.

## Required reading

Read each matching reference before work on that branch:

- Adding or moving programs, packages, settings, modules, or managed files: `docs/common-tasks.md`.
- Adding hosts: `docs/add-host.md`.
- Tracing repository layout, host inventory, or module flow, or changing host builders/module arguments: `docs/layout.md`.
- Adding Neovim plugins or implementing OS-specific or machine-specific behavior, including platform guards/module arguments: `docs/CODING_STANDARDS.md`.
- Creating, editing, wiring, or auditing secrets, including secret-backed MCP environment variables and containers: `docs/SECRETS_WORKFLOW.md`.
- After changes, or before Nix evaluation/builds, validation, or build-failure diagnosis/reporting: `docs/NIX_WORKFLOW.md`. Its validation procedure takes precedence over commands in other docs.
