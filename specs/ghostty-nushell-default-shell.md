## Feature: Use Nushell as Ghostty's default shell on all current Ghostty hosts

### Problem Statement
**Who:** Michael using Ghostty on the desktop/laptop hosts managed by this flake.
**What:** Ghostty should open directly into Nushell instead of inheriting the current account/login shell.
**Why it matters:** This gives a consistent terminal experience across macOS and Linux without changing system login shells.
**Evidence:** Ghostty is already configured centrally in `modules/home-manager/programs/ghostty.nix`, Nushell is already configured centrally in `modules/home-manager/programs/nushell.nix`, and the only host that explicitly disables Ghostty is `wanda`.

### Discovery
- Current Ghostty hosts are:
  - Darwin: `Michaels-M1-Max` (`personal-mac`)
  - Darwin: `Michael-Holtzscher-Work` (`work-mac`)
  - NixOS: `nixos-desktop`
- `wanda` is out of scope for implementation because `modules/home-manager/hosts/wanda/default.nix` forces `programs.ghostty.enable = false`.
- The repo already follows the right abstraction for this change:
  - shared user programs live in `modules/home-manager/programs/`
  - host-specific exceptions live in `modules/home-manager/hosts/<host>/`
- Login shells are currently separate concerns:
  - Darwin enables Zsh in `modules/darwin/darwin.nix`
  - NixOS sets `users.users.<user>.shell = pkgs.zsh` in `hosts/nixos/nixos-desktop/users.nix`
- Ghostty supports a `command` setting for the shell/command it launches, and supports explicit `shell-integration = nushell`.

### Proposed Solution
Make this a single shared Home Manager change in `modules/home-manager/programs/ghostty.nix`.

1. Extend the module to read the configured Nushell package from Home Manager (`config.programs.nushell.package`).
2. Derive the executable path from that package (`lib.getExe ...`) so Ghostty launches the same Nushell build managed by Nix on every OS.
3. Set Ghostty's default command to that Nushell executable.
4. Set `shell-integration = "nushell"` explicitly so Ghostty does not rely on shell filename detection.
5. Leave login shell configuration untouched on Darwin and NixOS.
6. Do not add any host-specific overrides unless validation proves one platform behaves differently.

Implementation should stay centralized because both Ghostty and Nushell are already shared user-level program modules. Host-specific duplication is unnecessary for the current host set.

### Scope & Deliverables
| Deliverable | Effort | Depends On |
|-------------|--------|------------|
| Update shared Ghostty module to launch Nushell by default | S | - |
| Validate Darwin and NixOS builds for all current Ghostty hosts | S | D1 |
| Document runtime verification and rollback notes in the change summary | S | D2 |

### Non-Goals (Explicit Exclusions)
- Changing the system/login shell for any user account
- Enabling Ghostty on `wanda`
- Reworking existing Zsh configuration
- Refactoring Nushell config beyond what is needed for Ghostty startup

### Data Model
No new data model.

Changed configuration contract:
- `programs.ghostty.settings.command` → absolute path to the managed `nu` executable
- `programs.ghostty.settings.shell-integration` → `"nushell"`

### API/Interface Contract
Input:
- Existing shared Home Manager config
- Existing `programs.nushell` enablement and package selection

Output:
- Ghostty launches Nushell for new windows/tabs on all enabled Ghostty hosts
- User/login shells remain unchanged outside Ghostty

Failure mode:
- If Ghostty or Nushell packaging differs unexpectedly by platform, validation should fail or runtime testing will show startup problems, in which case the fallback is to add a guarded override rather than changing login-shell behavior.

### Acceptance Criteria
- [ ] `modules/home-manager/programs/ghostty.nix` is the only implementation file needed for the behavior change.
- [ ] `Michaels-M1-Max`, `Michael-Holtzscher-Work`, and `nixos-desktop` all build successfully with safe build commands.
- [ ] After user activation, opening Ghostty on each target host starts Nushell directly.
- [ ] No login shell settings are changed in Darwin or NixOS modules.
- [ ] `wanda` remains unchanged because Ghostty is disabled there.

### Test Strategy
| Layer | What | How |
|-------|------|-----|
| Config/build | Nix evaluation/build on each Ghostty host target | `darwin-rebuild build --flake .#Michaels-M1-Max`, `darwin-rebuild build --flake .#Michael-Holtzscher-Work`, `nixos-rebuild build --flake .#nixos-desktop` |
| Runtime | Ghostty launches Nu | After user applies manually, run `ghostty +show-config | rg '^(command|shell-integration) ='` and open a new Ghostty window/tab to confirm an interactive Nu session |
| Regression | Login shells unchanged | Verify no edits were made to `modules/darwin/darwin.nix` or `hosts/nixos/nixos-desktop/users.nix` |

### Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Ghostty shell behavior differs between Darwin and Linux | Low | Medium | Keep the change in one shared module first; only add platform guards if validation/runtime testing proves necessary |
| Ghostty shell integration relies on detection heuristics | Medium | Low | Set `shell-integration = "nushell"` explicitly |
| Future host disables Nushell but still enables Ghostty | Low | Medium | Keep the implementation derived from `programs.nushell.package`; if needed later, add an assertion tying Ghostty's shell override to Nushell enablement |

### Trade-offs Made
| Chose | Over | Because |
|-------|------|---------|
| Shared Home Manager Ghostty change | Per-host overrides | Current behavior should be identical across the three Ghostty hosts |
| Ghostty-only shell override | Changing login shells | User explicitly wants Ghostty only and lower-risk rollout |
| Explicit Nushell shell integration | Implicit detection | More predictable across macOS and Linux |

### Open Questions
- [ ] None for the current scope.

### Success Metrics
- Ghostty opens directly into Nushell on both macOS hosts and the NixOS desktop.
- No host-specific hacks are required for the initial rollout.
- Existing login-shell behavior remains unchanged outside Ghostty.

---

# Ghostty + Nushell — Implementation Handoff

**Status:** Ready for task breakdown
**Effort:** S
**Date:** 2026-03-23

## Deliverables (Ordered)

1. **Shared Ghostty shell override** (S) — point Ghostty at the Nix-managed `nu` executable
   - Depends on: -
   - Files likely touched: `modules/home-manager/programs/ghostty.nix`

2. **Cross-platform validation** (S) — confirm the change evaluates/builds on both Darwin hosts and the NixOS host
   - Depends on: D1
   - Commands:
     - `darwin-rebuild build --flake .#Michaels-M1-Max`
     - `darwin-rebuild build --flake .#Michael-Holtzscher-Work`
     - `nixos-rebuild build --flake .#nixos-desktop`

3. **Runtime verification** (S) — confirm Ghostty actually starts in Nu after the user applies manually
   - Depends on: D2
   - Checks:
     - `ghostty +show-config | rg '^(command|shell-integration) ='`
     - open Ghostty and confirm the session is Nushell

## Key Technical Decisions
- Put the change in `modules/home-manager/programs/ghostty.nix` because this is shared user-level behavior.
- Derive the shell path from the configured Nushell package rather than hardcoding a platform-specific path.
- Keep Zsh as the account/login shell everywhere because shell scope is Ghostty-only.

## Acceptance Criteria
1. Ghostty launches Nushell on `personal-mac`, `work-mac`, and `nixos-desktop`.
2. No login shell settings change.
3. `wanda` remains unaffected.

## Rollback
- Remove the Ghostty `command` override (and explicit `shell-integration` setting if added).
- Rebuild the same three targets.
- No account shell rollback is required because login shells are unchanged.
