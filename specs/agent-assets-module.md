# Agent Assets Module - Implementation Spec

**Status:** Ready for task breakdown
**Type:** Feature plan
**Effort:** L
**Approved by:** user
**Date:** 2026-03-20

## Problem Statement

**Who:** repo maintainer managing agent assets in Home Manager.

**What:** agent markdown assets are installed with hardcoded per-tool paths today, starting with OpenCode. There is no reusable way to install the same asset set from local paths or pinned URLs into multiple agent runtimes.

**Why it matters:** adding Pi now, and Claude Code or Codex later, otherwise means duplicating path glue, source handling, and validation logic.

**Evidence:** `modules/home-manager/programs/opencode.nix` currently hardcodes `home.file` entries for `AGENTS.md`, `agents/`, `commands/`, `skills/`, and `plugins/`.

## Discovery

- Existing OpenCode assets live under `modules/home-manager/files/opencode/`.
- Existing Home Manager pattern uses `home.file` plus `recursive = true` for directory trees.
- OpenCode supports top-level docs, agents, commands, skills.
- Pi cleanly supports top-level docs and skills, not generic agents/commands.
- Claude Code later fits the same markdown model well.
- Codex later fits docs and skills, but not generic markdown agents.

## Proposed Solution

Add a new Home Manager module at `modules/home-manager/programs/agent-assets.nix`.

This module owns one canonical manifest for markdown-based agent assets. Callers declare assets by kind, source, and targets. The module resolves each source into a store path, validates file-vs-dir shape, maps it through a target adapter, checks collisions, and emits final `home.file` entries.

V1 ships adapters for OpenCode and Pi only. `modules/home-manager/programs/opencode.nix` stops hardcoding asset installs and instead declares manifest entries through this module. Future Claude Code and Codex support should be added as new adapters without redesigning the manifest model.

## Scope & Deliverables

| Deliverable | Effort | Depends On |
|-------------|--------|------------|
| D1. Add `agent-assets.nix` with typed options, source resolution, adapter mapping, and collision checks | L | - |
| D2. Import module from `modules/home-manager/programs/default.nix` | S | D1 |
| D3. Migrate existing OpenCode `AGENTS.md`, `agents`, `commands`, and `skills` installs to manifest-driven output with unchanged paths | M | D1 |
| D4. Add Pi adapter for top-level docs and skills under `~/.pi/agent` | M | D1 |
| D5. Add eval/integration coverage for local paths, pinned URL files, pinned URL archives, unsupported mappings, and collisions | M | D1 |

## Non-Goals

- project-local installs like `.pi/`, `.claude/`, `.codex/`, `.agents/`
- OpenCode `plugins`
- Pi prompts, themes, extensions, sessions, keybindings, or system prompt files
- Claude Code or Codex adapters in v1
- writable or copy-based installs
- unpinned remote sources
- translating generic agents or commands into runtimes that do not support them natively

## Module Boundaries

### `modules/home-manager/programs/agent-assets.nix`

Owns:

- typed option schema
- source normalization
- target adapter mapping
- destination collision assertions
- final `home.file` generation

### `modules/home-manager/programs/opencode.nix`

Owns:

- OpenCode package and settings
- manifest declarations for OpenCode assets

Does not own:

- direct `home.file` wiring for managed docs, agents, commands, or skills

### Future modules

- future Pi package/settings module may declare Pi-specific manifest entries
- future Claude/Codex support should be adapter additions, not schema redesign

## Data Model

Public API shape:

```nix
programs.agent-assets = {
  enable = true;

  targets = {
    opencode = {
      enable = true;
      root = "${config.xdg.configHome}/opencode";
    };

    pi = {
      enable = true;
      root = "${config.home.homeDirectory}/.pi/agent";
    };
  };

  docs."AGENTS.md" = {
    targets = [ "opencode" "pi" ];
    source = {
      type = "path";
      path = ../files/opencode/AGENTS.md;
    };
  };

  agents.oracle = {
    targets = [ "opencode" ];
    source = {
      type = "path";
      path = ../files/opencode/agents/oracle.md;
    };
  };

  commands.plan-spec = {
    targets = [ "opencode" ];
    source = {
      type = "path";
      path = ../files/opencode/commands/plan-spec.md;
    };
  };

  skills.spec-planner = {
    targets = [ "opencode" "pi" ];
    source = {
      type = "path";
      path = ../files/opencode/skills/spec-planner;
    };
  };
};
```

Canonical kinds:

- `docs.<filename>`
- `agents.<name>`
- `commands.<name>`
- `skills.<name>`

Name rules:

- `docs` keys must be basenames only and end in `.md`
- `agents`, `commands`, `skills` keys must be slash-free slugs

Source variants:

```nix
{ type = "path"; path = ./local-file-or-dir; }

{ type = "url-file"; url = "https://example.com/foo.md"; hash = "sha256-..."; }

{ type = "url-archive"; url = "https://example.com/skill.tar.gz"; hash = "sha256-..."; subpath = "spec-planner"; }
```

Kind/source shape rules:

- `docs`, `agents`, `commands` must resolve to files
- `skills` must resolve to directories
- local shape mismatches fail evaluation
- remote archive selection uses explicit `subpath`; no archive-root guessing

## Target Adapter Contract

Each adapter defines:

- supported kinds
- install root
- `destFor(kind, name)` mapping

### OpenCode adapter

Root: `${config.xdg.configHome}/opencode` by default.

Mappings:

- `docs."AGENTS.md"` -> `${root}/AGENTS.md`
- `agents.oracle` -> `${root}/agents/oracle.md`
- `commands.plan-spec` -> `${root}/commands/plan-spec.md`
- `skills.spec-planner` -> `${root}/skills/spec-planner`

### Pi adapter

Root: `${config.home.homeDirectory}/.pi/agent` by default.

Mappings:

- `docs."AGENTS.md"` -> `${root}/AGENTS.md`
- `skills.spec-planner` -> `${root}/skills/spec-planner`

Unsupported in v1:

- `agents.* -> pi`
- `commands.* -> pi`

Unsupported mappings must fail evaluation with the asset id and target name in the error.

## Generation Rules

- File kinds install with `home.file."<dest>".source = resolvedPath`.
- Skill directories install with `home.file."<dest>" = { source = resolvedPath; recursive = true; };`
- All installs use store symlinks only.
- No activation copy steps.
- Target roots are configurable through `targets.opencode.root` and `targets.pi.root`.

## Collision Policy

The module must fail evaluation on both:

- exact collisions: two assets map to the same destination
- prefix collisions: one asset destination is a parent of another destination

Examples that must fail:

- `${root}/skills/foo`
- `${root}/skills/foo/SKILL.md`

Collision checks must run after target mapping, not on manifest keys alone.

## API / Interface Contract

- disabled target means manifest entries for that target produce no output
- enabled target plus valid asset produces exactly one destination mapping
- unsupported kind/target pair fails evaluation
- missing hash for remote source fails option validation
- malformed `docs` filename or slash-containing asset key fails evaluation
- local path shape mismatch fails evaluation

## Likely Files Touched

- `modules/home-manager/programs/agent-assets.nix`
- `modules/home-manager/programs/default.nix`
- `modules/home-manager/programs/opencode.nix`
- optionally new fixture/test files if repo has a preferred eval-test location

## Acceptance Criteria

- [ ] `modules/home-manager/programs/agent-assets.nix` exists
- [ ] `modules/home-manager/programs/default.nix` imports the new module
- [ ] module exposes typed options for `docs`, `agents`, `commands`, and `skills`
- [ ] module supports `path`, `url-file`, and `url-archive` source variants
- [ ] remote variants require explicit hashes
- [ ] module exposes configurable `targets.opencode.root` and `targets.pi.root`
- [ ] OpenCode managed asset installs are removed from hardcoded `home.file` wiring in `modules/home-manager/programs/opencode.nix`
- [ ] resulting OpenCode install paths remain unchanged
- [ ] Pi installs at least one top-level doc and one skill tree under `~/.pi/agent`
- [ ] unsupported mappings like `agents.* -> pi` fail with clear errors
- [ ] exact and prefix collisions fail with clear errors
- [ ] `nix flake check` passes

## Test Strategy

| Layer | What | How |
|-------|------|-----|
| Eval | key validation | assert docs basename rules and slash-free slug rules |
| Eval | adapter validation | assert unsupported `agents` or `commands` on Pi fail |
| Eval | collision detection | assert exact and prefix collisions fail |
| Integration | local file source | HM fixture installs one markdown file |
| Integration | local skill dir source | HM fixture installs one recursive skill tree |
| Integration | pinned remote file | use pinned `file://` fixture URL if practical in tests |
| Integration | pinned remote archive | use pinned `file://` archive fixture plus `subpath` |
| Repo | final validation | run `nix flake check` |

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scope creep into project-local installs | High | High | keep v1 global-only |
| Archive structure ambiguity | Medium | Medium | require explicit `subpath` |
| Destination collisions hidden until runtime | Medium | High | detect after target mapping during eval |
| Symlinked skill trees assume writable contents | Low | Medium | document store-symlink-only contract |
| Overfitting schema to OpenCode | Medium | High | keep canonical kinds generic and adapter-driven |

## Trade-offs Made

| Chose | Over | Because |
|-------|------|---------|
| generic manifest core | per-client module API | one canonical model, less duplicate glue |
| attrsets by kind | flat list of items | safer names, simpler merges, fewer illegal states |
| store symlinks | activation copy | simpler, reproducible, matches HM patterns |
| pinned URL support | best-effort remote fetch | reproducibility |
| global-only v1 | global plus project-local | bounded scope |
| native adapter matrix | translation shims | runtime semantics differ too much |

## Success Metrics

- adding a new asset needs one manifest declaration, not new `home.file` glue
- one skill directory can target both OpenCode and Pi from one declaration
- future Claude/Codex support can land as adapter work, not schema redesign
- OpenCode asset path wiring in `modules/home-manager/programs/opencode.nix` drops to near-zero

## Open Questions

- none blocking

---

*Spec approved for task decomposition.*
