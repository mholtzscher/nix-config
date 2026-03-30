# Migrate agent skill management to `agent-skills-nix`

## Goal
Replace the current manual per-agent skill wiring with a single declarative `agent-skills-nix` setup that installs one shared skill bundle for both pi and opencode across all hosts, while keeping the existing repo-local skill content as the source of truth.

## Why
Today the same concern is spread across three places:
- `modules/home-manager/agents/files/skills/default.nix` maps skill names to paths
- `modules/home-manager/agents/pi.nix` selects and installs pi skills
- `modules/home-manager/agents/opencode.nix` selects and installs opencode skills

That duplication makes adds/removals easy to drift. `agent-skills-nix` can discover `SKILL.md` directories, build one bundle, and sync it to multiple targets declaratively.

## Context
Current repo shape:
- `modules/home-manager/agents/files/skills/*/SKILL.md` already contains the actual skill content
- `pi.nix` and `opencode.nix` each build `home.file` entries for skill directories
- pi and opencode currently differ slightly (`librarian` exists in opencode but not pi)
- user explicitly chose the post-migration model to be:
  - both pi and opencode
  - all hosts
  - pinned flake input updates
  - one shared bundle for both agents
  - declarative install/wiring

Upstream findings from `Kyure-A/agent-skills-nix`:
- the Home Manager module supports custom targets
- one module instance produces one bundle and syncs it to all enabled targets
- `symlink-tree` is the default global-target structure and leaves the root writable
- discovery is recursive by default, so `filter.maxDepth = 1` is useful to preserve this repo's current flat skill layout semantics
- sync uses `rsync --delete` semantics and excludes `/.system` by default

## Reuse and existing patterns
Reuse:
- existing skill directory contents at `modules/home-manager/agents/files/skills/`
- existing `!isWork` gating pattern from `modules/home-manager/agents/pi.nix`
- existing `config.xdg.configHome` usage pattern from `modules/home-manager/agents/opencode.nix`
- existing `modules/home-manager/agents/default.nix` import aggregation pattern
- existing host validation workflow from `AGENTS.md`

Do not reuse:
- manual `skillSources` import pattern in `pi.nix`/`opencode.nix`
- per-agent skill lists in both files
- `modules/home-manager/agents/files/skills/default.nix` source map

## Recommended approach
Adopt `agent-skills-nix` as the skill discovery/bundle/install layer, but keep local skills in-repo.

This is the lowest-churn design because it:
- preserves your current skills directory layout
- keeps updates pinned in `flake.lock`
- removes duplicated wiring logic
- matches your chosen one-bundle model without extra abstraction

## Files to modify
1. `flake.nix`
2. `modules/home-manager/agents/default.nix`
3. `modules/home-manager/agents/pi.nix`
4. `modules/home-manager/agents/opencode.nix`
5. `modules/home-manager/agents/files/skills/README.md`
6. `modules/home-manager/agents/files/skills/default.nix` (remove or leave unused, preferably remove)
7. `modules/home-manager/agents/agent-skills.nix` (new)

## Proposed design

### 1. Add flake input
Add a new top-level flake input:

```nix
agent-skills = {
  url = "github:Kyure-A/agent-skills-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Also thread it through the `outputs` input set like the other inputs.

### 2. Add a shared Home Manager module
Create `modules/home-manager/agents/agent-skills.nix`.

Responsibilities:
- import `inputs.agent-skills.homeManagerModules.default`
- configure `programs.agent-skills.enable = true`
- point `sources.local.path` at `./files/skills`
- set `filter.maxDepth = 1`
- define one shared `skills.enable` list
- define two custom targets: `pi` and `opencode`

### 3. Shared skill list
Use one shared bundle for both agents.

Initial list:
- `atlassian-api`
- `build-skill`
- `conventional-commits`
- `gradle`
- `index-knowledge`
- `librarian`
- `mermaid`
- `spec-planner`

Notes:
- this intentionally adds `librarian` to pi
- `atlas-cli` stays out unless explicitly requested later

### 4. Custom targets
Define custom targets because upstream does not ship pi/opencode defaults.

Planned shape:

```nix
programs.agent-skills.targets.pi = {
  enable = !isWork;
  dest = "$HOME/.pi/agent/skills";
  structure = "symlink-tree";
};

programs.agent-skills.targets.opencode = {
  enable = true;
  dest = "${config.xdg.configHome}/opencode/skills";
  structure = "symlink-tree";
};
```

Rationale:
- pi currently has `!isWork` gating and should keep it
- opencode skills should remain available where opencode config is currently present
- `symlink-tree` matches upstream behavior and avoids generating one `home.file` entry per skill

### 5. Simplify `pi.nix`
Remove only the skill-management pieces:
- `skillSources`
- `piSkills`
- `mkSkillFiles`
- `skillFiles`
- inclusion of `skillFiles` in `home.file`

Keep:
- pi package install
- `.pi/agent/settings.json`
- themes
- prompts
- extensions
- existing `!isWork` guards

### 6. Simplify `opencode.nix`
Remove only the skill-management pieces:
- `skillSources`
- `opencodeSkills`
- `mkSkillFiles`
- `skillFiles`
- inclusion of `skillFiles` in `home.file`

Keep:
- `OPENCODE_ENABLE_EXPERIMENTAL_MODELS`
- opencode `agents`, `commands`, `plugins`, `AGENTS.md`
- program settings
- package enablement

### 7. Update module imports
Add `./agent-skills.nix` to `modules/home-manager/agents/default.nix` so the new shared module loads with the rest of the agent stack.

### 8. Remove obsolete map
After migration, `modules/home-manager/agents/files/skills/default.nix` should no longer be referenced.

Preferred outcome:
- remove the file

Fallback:
- leave it temporarily unused if removal causes unnecessary churn during the implementation step

### 9. Update docs
Revise `modules/home-manager/agents/files/skills/README.md` to reflect the new flow:
1. create `modules/home-manager/agents/files/skills/<name>/SKILL.md`
2. add the skill ID to the shared allowlist in `modules/home-manager/agents/agent-skills.nix`
3. no source-map edits required
4. no per-agent skill list edits required

## Ordered implementation steps
1. Add `agent-skills` to `flake.nix`
2. Create `modules/home-manager/agents/agent-skills.nix`
3. Import the new module from `modules/home-manager/agents/default.nix`
4. Remove skill wiring from `modules/home-manager/agents/pi.nix`
5. Remove skill wiring from `modules/home-manager/agents/opencode.nix`
6. Remove or orphan `modules/home-manager/agents/files/skills/default.nix`
7. Update `modules/home-manager/agents/files/skills/README.md`
8. Validate all affected builds

## Acceptance criteria
- `flake.nix` contains a pinned `agent-skills` input
- local skill discovery uses `modules/home-manager/agents/files/skills`
- only one shared enabled-skill list exists
- `pi.nix` no longer manually installs skills
- `opencode.nix` no longer manually installs skills
- `modules/home-manager/agents/files/skills/default.nix` is removed or unused
- pi skills land at `~/.pi/agent/skills` on non-work setups only
- opencode skills land at `${XDG_CONFIG_HOME}/opencode/skills`
- unknown skill IDs would fail evaluation rather than silently drift
- implementation is validated only with build commands, never switch/apply

## Risks and mitigations
- **Risk:** `rsync --delete` removes unmanaged files in the skills target directories
  - **Mitigation:** treat `~/.pi/agent/skills` and `~/.config/opencode/skills` as fully managed directories
- **Risk:** future desire for separate pi/opencode bundles
  - **Mitigation:** accept current one-bundle model; if requirements change later, split into separate module instances or use upstream library functions directly
- **Risk:** recursive discovery picks up nested skills unexpectedly
  - **Mitigation:** set `filter.maxDepth = 1`
- **Risk:** work-host behavior changes unintentionally
  - **Mitigation:** preserve pi `!isWork` gating and validate the work host build explicitly

## Verification
Per repo policy, build only:
- `darwin-rebuild build --flake .#Michaels-M1-Max`
- `darwin-rebuild build --flake .#Michael-Holtzscher-Work`
- `nixos-rebuild build --flake .#nixos-desktop`
- `home-manager build --flake .#wanda`

Additional review checks:
- grep for leftover `skillSources`, `piSkills`, `opencodeSkills`, and imports of `./files/skills`
- confirm `README.md` no longer instructs editing the deleted source map

## Non-goals
- migrating prompts, themes, extensions, commands, or agents into `agent-skills-nix`
- introducing external/upstream skill content sources in this step
- creating per-host skill variance
- changing opencode or pi program settings unrelated to skill installation

## Final recommendation
Proceed with the shared-module integration approach.

It is the best fit because it removes the duplicated manual wiring while preserving your existing skill content and host behavior, and it aligns cleanly with how `agent-skills-nix` is designed to operate.
